#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/fs.h>
#include <linux/slab.h>
#include <linux/scatterlist.h>
#include <crypto/skcipher.h>
#include <linux/uaccess.h>

#define DEVICE_NAME "my_device"

// Объявления функций для обработки
static ssize_t my_read(struct file *file, char __user *buf, size_t len, loff_t *offset);
static ssize_t my_write(struct file *file, const char __user *buf, size_t len, loff_t *offset);

// Операции для устройства
static struct file_operations my_fops = {
    .owner = THIS_MODULE,
    .read = my_read,
    .write = my_write,
};

struct crypto_skcipher *skcipher = NULL;
struct skcipher_request *req = NULL;
struct scatterlist sg;
char key[32] = "thisiskeyforsymmetricencryption";

// Инициализация шифрования
static int init_cipher(void) {
    skcipher = crypto_alloc_skcipher("cbc(aes)", 0, 0);
    if (IS_ERR(skcipher)) {
        printk(KERN_ERR "Failed to allocate skcipher handle\n");
        return PTR_ERR(skcipher);
    }

    req = skcipher_request_alloc(skcipher, GFP_KERNEL);
    if (!req) {
        printk(KERN_ERR "Failed to allocate skcipher request\n");
        crypto_free_skcipher(skcipher);
        return -ENOMEM;
    }

    if (crypto_skcipher_setkey(skcipher, key, 32)) {
        printk(KERN_ERR "Failed to set key\n");
        skcipher_request_free(req);
        crypto_free_skcipher(skcipher);
        return -EAGAIN;
    }

    return 0;
}

// Функция для шифрования данных
static int encrypt_data(char *data, int len) {
    int ret;

    sg_init_one(&sg, data, len);
    skcipher_request_set_crypt(req, &sg, &sg, len, NULL);
    
    ret = crypto_skcipher_encrypt(req);
    if (ret) {
        printk(KERN_ERR "Encryption failed\n");
        return ret;
    }

    return 0;
}

// Функция для расшифровки данных
static int decrypt_data(char *data, int len) {
    int ret;

    sg_init_one(&sg, data, len);
    skcipher_request_set_crypt(req, &sg, &sg, len, NULL);
    
    ret = crypto_skcipher_decrypt(req);
    if (ret) {
        printk(KERN_ERR "Decryption failed\n");
        return ret;
    }

    return 0;
}

// Завершение работы с шифрованием
static void cleanup_cipher(void) {
    skcipher_request_free(req);
    crypto_free_skcipher(skcipher);
}

// Функция для записи
static ssize_t my_write(struct file *file, const char __user *buf, size_t len, loff_t *offset) {
    char *kbuf;
    ssize_t ret;

    // Выделяем память для буфера
    kbuf = kmalloc(len, GFP_KERNEL);
    if (!kbuf)
        return -ENOMEM;

    if (copy_from_user(kbuf, buf, len)) {
        kfree(kbuf);
        return -EFAULT;
    }

    // Шифруем данные перед записью
    ret = encrypt_data(kbuf, len);
    if (ret < 0) {
        kfree(kbuf);
        return ret;
    }

    // Здесь мы просто отдаем те же зашифрованные данные
    if (copy_to_user(buf, kbuf, len)) {
        kfree(kbuf);
        return -EFAULT;
    }

    kfree(kbuf);
    return len; // Возвращаем количество записанных байтов
}

// Функция для чтения
static ssize_t my_read(struct file *file, char __user *buf, size_t len, loff_t *offset) {
    char *kbuf;
    ssize_t ret;

    // Выделяем память для буфера
    kbuf = kmalloc(len, GFP_KERNEL);
    if (!kbuf)
        return -ENOMEM;

    // Здесь мы просто вернем нули или какие-то данные
    memset(kbuf, 0, len); // Пример заполнения нулями

    // Расшифровываем данные после чтения
    ret = decrypt_data(kbuf, len);
    if (ret < 0) {
        kfree(kbuf);
        return ret;
    }

    if (copy_to_user(buf, kbuf, len)) {
        kfree(kbuf);
        return -EFAULT;
    }

    kfree(kbuf);
    return len; // Возвращаем количество прочитанных байтов
}

// Основные функции модуля
static int __init my_module_init(void) {
    // Инициализация шифрования и регистрация устройства
    int ret = init_cipher();
    if (ret) {
        return ret;
    }

    if (register_chrdev(0, DEVICE_NAME, &my_fops) < 0) {
        cleanup_cipher();
        return -EBUSY;
    }

    return 0;
}

static void __exit my_module_exit(void) {
    unregister_chrdev(0, DEVICE_NAME);
    cleanup_cipher();
}

module_init(my_module_init);
module_exit(my_module_exit);

MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("My Crypto Module");
MODULE_AUTHOR("Elizaveta");

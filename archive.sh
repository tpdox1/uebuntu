SOURCE_DIR="$LFS/sources"
BUILD_DIR="$LFS/build"
INSTALL_PREFIX="/usr"

mkdir -p $BUILD_DIR

export LFS
export PATH="/tools/bin:/bin:/usr/bin:$PATH"

for archive in "$SOURCE_DIR"/*.tar*; do
    echo "Распаковываем $archive"
    tar -xf "$archive" -C "$BUILD_DIR"

    folder_name=$(tar -tf "$archive" | head -1 | cut -f1 -d"/")
    cd "$BUILD_DIR/$folder_name"

    echo "Конфигурируем $folder_name"
    ./configure --prefix=$INSTALL_PREFIX

    echo "Собираем $folder_name"
    make

    echo "Устанавливаем $folder_name"
    make install

    echo "Чистим папку $folder_name"
    cd "$BUILD_DIR"
    rm -rf "$folder_name"

    echo "$folder_name установлен и исходники удалены"
done

echo "Все пакеты установлены"

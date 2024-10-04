for file in *.tar.xz; do
    [ -f "$file" ] && tar -xf "$file"
done

for file in *.tar.gz; do
    [ -f "$file" ] && tar -xzf "$file"
done

for file in *.tar.bz2; do
    [ -f "$file" ] && tar -xjf "$file"
done

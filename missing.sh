for ver in $(./bake latest)
do
    test "$(find debian/*/dist -name "*$ver*.deb")" || echo $ver
done

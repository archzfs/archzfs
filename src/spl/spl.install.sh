#!/bin/bash

cat << EOF > ${spl_pkgbuild_path}/spl.install
post_install() {
    run_depmod
}

post_remove() {
    run_depmod
}

post_upgrade() {
    run_depmod
}

run_depmod() {
    echo ">>> Updating SPL module dependencies"
    depmod -a \$(cat /usr/lib/modules/${kernel_mod_path}/version)
}
EOF

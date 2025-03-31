make clean; make -j 64; make modules -j 64; sudo make INSTALL_MOD_STRIP=1 modules_install; sudo make install

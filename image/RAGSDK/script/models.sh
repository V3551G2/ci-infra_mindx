git clone -q --depth 1 -b out https://jiofw:Stmzo8T_iZ5fQgrrzMPnG37r@gitcode.com/Ascend/VisionSDK.git
cd VisionSDK/test/models && cat file_part* > models.zip
ls models.zip
unzip -q models.zip -d /home/simon
cd $HOME
mkdir -p external && cd external
mkdir -p sdrplayapi && cd sdrplayapi

git clone https://github.com/srcejon/sdrplayapi.git
cd sdrplayapi
sed -i s/more\ -d/cat/ install_lib.sh
if [ "$(id -u)" -eq 0 ]; then
  yes | bash install_lib.sh
else
  sudo bash -c 'yes | bash install_lib.sh'
fi

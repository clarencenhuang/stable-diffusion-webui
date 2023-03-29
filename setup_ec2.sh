# disable the restart dialogue and install several packages
# sudo sed -i "/#\$nrconf{restart} = 'i';/s/.*/\$nrconf{restart} = 'a';/" /etc/needrestart/needrestart.conf
sudo yum update -y
sudo yum install wget git build-essential net-tools awscli openssl11 bzip2-devel xz-devel -y
sudo yum install -y gcc kernel-devel-$(uname -r)

# install CUDA (from https://developer.nvidia.com/cuda-downloads)
wget https://developer.download.nvidia.com/compute/cuda/12.0.0/local_installers/cuda_12.0.0_525.60.13_linux.run
sudo sh cuda_12.0.0_525.60.13_linux.run --silent

# install git-lfs
curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.rpm.sh | sudo bash
sudo yum install git-lfs -y
sudo -u ec2-user git lfs install --skip-smudge

# Install OpenSSL 1.1.1
mkdir -p /opt
cd /opt
curl https://ftp.openssl.org/source/old/1.1.1/openssl-1.1.1j.tar.gz --output openssl.tar.gz
tar xzf openssl.tar.gz
rm openssl.tar.gz
cd openssl-1.1.1j/
./config --prefix=/opt/openssl && make && make install


# Install Python 3.10.6
cd /opt
wget https://www.python.org/ftp/python/3.10.6/Python-3.10.6.tgz
tar xzf Python-3.10.6.tgz
cd Python-3.10.6
./configure --with-openssl=/opt/openssl
make
sudo make altinstall


# clone stable diffusion UX
git clone https://github.com/clarencenhuang/stable-diffusion-webui.git

# download the SD model v2.1 and move it to the SD model directory
sudo -u ec2-user git clone --depth 1 https://huggingface.co/stabilityai/stable-diffusion-2-1-base
cd stable-diffusion-2-1-base/
sudo -u ec2-user git lfs pull --include "v2-1_512-ema-pruned.ckpt"
sudo -u ec2-user git lfs install --force
cd ..
mv stable-diffusion-2-1-base/v2-1_512-ema-pruned.ckpt stable-diffusion-webui/models/Stable-diffusion/
rm -rf stable-diffusion-2-1-base/

# download the corresponding config file and move it also to the model directory (make sure the name matches the model name)
wget https://raw.githubusercontent.com/Stability-AI/stablediffusion/main/configs/stable-diffusion/v2-inference.yaml
cp v2-inference.yaml stable-diffusion-webui/models/Stable-diffusion/v2-1_512-ema-pruned.yaml

# change ownership of the web UI so that a regular user can start the server
sudo chown -R ec2-user:ec2-user stable-diffusion-webui/

# start the server as user 'ec2-user'
# sudo -u ec2-user nohup bash stable-diffusion-webui/webui.sh --listen > log.txt
webui.sh --listen

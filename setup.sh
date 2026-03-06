  #!/bin/bash
  
  sudo su
  sudo apt update -y
  sudo apt install -y git nano wget dos2unix
  git clone https://github.com/onixsat/linux.git
  dos2unix linux/*
  find -name '*.sh' -print0 | xargs -0 dos2unix
  cd linux
  bash btk.sh

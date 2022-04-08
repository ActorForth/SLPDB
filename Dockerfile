# A Docker container for running SLPDB. 

#### BEGIN BOILERPLATE SETUP

FROM ubuntu:18.04
LABEL maintainer="Nicolai Skye <nicolaiskye@icloud.com>"

# Update the OS and install any OS packages needed.
RUN apt-get update -y
RUN apt-get install -y sudo git curl nano gnupg wget

#Install Node and NPM
RUN curl -sL https://deb.nodesource.com/setup_12.x -o nodesource_setup.sh
RUN bash nodesource_setup.sh
RUN apt-get install -y nodejs build-essential

#Create the user 'safeuser' and add them to the sudo group.
RUN useradd -ms /bin/bash safeuser
RUN adduser safeuser sudo

#Set password to 'abcd8765' change value below if you want a different password
RUN echo safeuser:abcd8765 | chpasswd

#Set the working directory to be the users home directory
WORKDIR /home/safeuser
#### END BOILERPLATE SETUP

# SLPDB specific packages
RUN apt-get install -y autoconf libtool
RUN npm install -g typescript

#Setup NPM for non-root global install (like on a mac)
RUN mkdir /home/safeuser/.npm-global
RUN chown -R safeuser .npm-global
RUN echo "export PATH=~/.npm-global/bin:$PATH" >> /home/safeuser/.profile
RUN runuser -l safeuser -c "npm config set prefix '~/.npm-global'"


# Switch to user account.
USER safeuser
# Prep 'sudo' commands.
#RUN echo 'abcd8765' | sudo -S pwd

# Clone the SLPDB repository
WORKDIR /home/safeuser

# Use docker cache for npm stuff, unless some dependency changes. code-only change will not invalidate this cache
COPY package.json .
# It is upto the developer who adjusts dependency to commit the new shrinkwrap
COPY npm-shrinkwrap.json .
RUN npm ci

COPY . .


VOLUME /home/safeuser/config

COPY startup-script.sh start.sh
CMD ["./start.sh"]

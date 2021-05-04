FROM mcr.microsoft.com/powershell:latest

RUN apt-get -y update
RUN apt-get -y install wget

RUN wget https://packages.microsoft.com/config/ubuntu/16.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
RUN dpkg -i packages-microsoft-prod.deb

RUN apt-get -y update
RUN apt-get -y install git
RUN apt-get -y install apt-transport-https
RUN apt-get -y update
RUN apt-get -y install dotnet-sdk-5.0

RUN mkdir /pester
RUN mkdir /TestOutput

ADD . /pester

docker build -t umn-autopackager .

docker run -v C:\DockerMount:/BuildOutput -it --name umn-autopackager -w /pester umn-autopackager:latest pwsh -file .\build\build.ps1

docker container stop umn-autopackager

docker rm -f umn-autopackager

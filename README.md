![HRC Logo](https://github.com/KD5FMU/Internet-Monitor-ASL3/blob/main/Internet%20Monitor.png)

# Internet-Monitor-ASL3
This script/service will have your node check for an internet connection every minute. Once internet is not detected the node will announce locally "Internet Disconnected" and then attempt to re-connect. Once the internet connection is re-established then the node will announce "Internet re-connected".

## About Internet Monitor

Do you have a mobile AllStarLink Node? Have you ever taken a lengthy journey in a vehicle with your mobile AllStarLink Node and connect to a HUB or a friend;s Node and as you travel in and out of bad coverage areas you connection to the internet drops and so does your AllStarLink connection. The real problem is, a lot of time most likely has passed by and they may have been trying to contact you but your isolated to the world becuase your internet dropped and most likley will re-connect but you don't know it. 

Yes this has happened to me and countless others and "at-best" it's an annoyance and very inconvenient. So that's where this idea comes from. 

BUT!!

It's not perfect and needs testing and ANY contributions will be seriously considered. This is another step in making the AllStarLink experience even better!

## Start Here

Download the Installation Script file.
```
sudo wget https://raw.githubusercontent.com/KD5FMU/Internet-Monitor-ASL3/refs/heads/main/install_internet_monitor.sh
```

Then we need to make it executable
```
sudo chmod +x install_internet_monitor.sh
```
Then we can execute and get the install moving
```
sudo ./install_internet_monitor.sh
```

Then give it a good test

73 and Report Back


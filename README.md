# Install-FastDDS
Install any version of FastDDS locally and its dependencies on Debian based systems.

The script installs any version of eProsima's Fast-DDS gloabally via its source code and generates a Fast-DDS example program linked to the installed code.

__Be aware of relative pathing if the user decides to expand the script.__

Fast-DDS Github: [Github](https://github.com/eProsima/Fast-DDS)

FastDDS is an open-source implementation of the Data Distribution Service (DDS) standard, developed by eProsima. DDS is a middleware protocol designed for real-time, high-performance, data-centric secure communication in distributed systems. Fast DDS uses RTPS wire protocl that provides publisher-subscriber communication over transports such as TCP/UDP/IP which guarantees compatability among different DDS implementations.

In the relm of distributed architectures, it is easy to start with a contemporary autonomous vehicle design where there are lots of sensors integrated into a single centralized place. Using DDS allows for a data centric approach which allows you to take the software that was centralized and distribute it so it reduces redundancy. Furthermore, DDS allows for the system to only deal with the data and not get it to different places. The system is then able to reason about the state of the machine rather than focus on what's being said vs. what actually is. 

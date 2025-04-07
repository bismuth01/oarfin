<<<<<<< HEAD
# oarfin
=======
# Oarfin

Oarfin is a Natural Disaster Alert and Management System.

It consits of 4 main parts: - (This is a breif overview, more details are present in `README` of each folder)
- Website
- App
- APIs
- Server

### Website
The Website is made for the relevant authorities which provides a live map of the current disaster worldwide, with affected areas and the number of app users in the affected region. Authorities have the option to add safe areas which gets notified to app users, and information scrapped about disasters is also presented.

### App
The App is made for users. On detection of a danger zone, the user it immediately notified, the location is sent to the authorities and the people added in the app are notified about the users location too. The user can try to get out of the danger zone, or follow instructions to be safe during the disaster. Safe areas added by authorities can also been seen by the user and attempted to reach.

### APIs
The APIs scrape the online world to get articles and posts related to disasters and present it to the website. This enables authorities to get maximum information about the disaster.

### Server
The Server sits at the heart of communication of the above 3 parts. Not only it enables data transfer and communication but also maintains a database which maintains data across all instances of websites and apps and can also be used for data science.

## System Architecture
![image](https://github.com/user-attachments/assets/2b34fafa-4698-43d8-b821-28fb717e3626)

## Security Measures
To secure the system, all APIs have error handling and CORS protection. The database in the server uses `sqllite3` which has inbuilt sql injection protection.
>>>>>>> c8e5cd36d60add68fb942b13c7243a98c3968775

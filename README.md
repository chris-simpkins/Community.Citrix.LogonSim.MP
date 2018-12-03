# Getting started with the Community Citrix Logon Simulator MP

## What is the Citrix Logon Simulator MP?

It's a Microsoft System Center Operations Manager (SCOM) management pack for simulating logons to Citrix XenApp and XenDesktop via NetScaler or Storefront in a web browser. You will need SCOM to use the management pack.

Once installed and configured, the management pack will perform regular, automated application launches in your Citrix environment to ensure your applications are available to end users. Using SCOM, you can configure email notifications for any failures, build dashboards to show real-time availability,and create management reports to demonstrate Citrix uptime and availability.

### The Script

The MP works by running a Powershell script on a test client. The script uses Selenium Webdriver to simulate a user logging on to the specified Citrix environment and launching an application through a web browser. It will then verify whether the application launched successfully.

Depending on whether the script runs successfully, an exit code will be returned which the SCOM monitor interprets as either a pass or a fail on the availability of Citrix.

Further details on the script execution steps can be found found in Step 2 of the "Getting Started" section.

## Getting started

This GitHub repository contains the source files. The downloadable management pack and associated files can be found here:

https://download.squaredup.com/management-packs/citrix-logon-simulator-community/

To install the Logon Simulator you will need:

- SCOM 2012 R2 (earlier versions may be supported but are untested)
- Citrix XenDesktop or XenApp accessible through a web browser
- A user account that will be used to perform the logons. The account must have access to one or more desktops or applications.
- A test application (e.g. Notepad) or desktop that will be launched. The above user must have access to the application.
- A test machine with Internet Explorer installed, from where the logons will be made

The Logon Simulator is split into two parts:
1. A management pack that the SCOM administrator will need to install
2. A set of files that are installed on a test client and should be managed by the Citrix administrator

### Step 1 – Install the SCOM Management Pack

Import the management pack `Community.Citrix.LogonSimulator.mpb` into SCOM using the standard process.

The MP will show up as `Citrix Logon Simulator (Community MP)`.

The MP adds a new Run As Profile called `Citrix Logon Simulator User Account`. This must be configured with a user account that will be used for the simulated logons. Ensure that the user account is configured to be distributed by SCOM to the test client(s).

The MP also adds a discovery called `Discover Citrix Logon Simulator Test`. This can be viewed in the SCOM console under `Authoring > Management Pack Objects > Object Discoveries`.

The discovery is set to run every hour by default, on all Windows Computers. You can override the discovery to run more regularly on your target client machines.

### Step 2 – Prepare the client test machine

Now we’re ready to configure the client test machine. This should be done on one or more Windows computers that will run the simulated logons. You may want to start by testing with a regular server in your data centre, and then experiment with test clients elsewhere in your organisation, such as remote sites, branch offices or even the public cloud.

Let's break this down into several smaller steps:

#### Select and prepare a test client machine:

The machine must be a Windows computer monitored by SCOM.

Verify the user logon by manually browsing to your StoreFront URL, logon with the **test user credentials** and launch the test application.

**REALLY IMPORTANT** - Verify that the logon and application launch involves no pop-up dialogs, file downloads or other user interruptions and the URL is accessible from the test machine. Ensure the browser zoom is set to 100% and protected mode is enabled for **ALL** zones. The tested application must also be available on the front page after user logon, i.e. in the user recents/favourites. 

#### Configure and test the script: 

1. Unzip the ClientFiles.zip to the C: drive on the test client. This should create the following folder structure:
 
```
C:\
  Monitoring\
    Citrix\
      Example Configuration Files\
      Scripts\
```
2. Configure the machine as a test client so that SCOM will automatically run the script.
    1. Copy the config.json from `C:\Monitoring\Citrix\Example Configuration Files` to `C:\Monitoring\Citrix`
    2. Edit the file, replacing the placeholder values with the details for your environment.
    3. Make sure to enter the name of the script that matches your environment in the **testScript** field (i.e. If you are running StoreWeb you would use StoreWeb-18.xx.ps1)

3. In an elevated Powershell session, run the script `Test-Setup.ps1`, entering the Citrix logon user's credentials when prompted. This script replicates the method in which the SCOM agent will run the script.

    Verify that the script performs the following actions:
    - Opens IE
    - Logs on
    - Checks for logon errors
    - Checks for "lite version pop-up"
    - Launches the app
    - Waits
    - Closes IE

### Step 3 - Check everything's working

That’s it! SCOM should now discover the config.json file, create new `Citrix Logon Simulator Test` objects hosted on the `Windows Computer` object to represent the tests, and start executing the logon script.

To verify the test clients are discovered and the tests are running, you can use the SCOM console:

Navigate to `Monitoring > Discovered Inventory` and change the type to `Citrix Logon Simulator Test`. You should see the test clients appear. Click on one to see its properties. There will also be an agent task available called `View Last Logon Result` that you can use to view the most recent test log.

## Need help?

This management pack is a community management originally developed by Squared Up (http://www.squaredup.com).

For help and advice, post questions on http://community.squaredup.com/answers.

## Can you improve the script or management pack?

If you want to suggest some fixes or improvements to the script or management pack, raise an issue on [the GitHub Issues page](https://github.com/squaredup/Community.Citrix.LogonSim.MP/issues) or better, submit the suggested change as a [Pull Request](https://github.com/squaredup/Community.Citrix.LogonSim.MP/pulls).
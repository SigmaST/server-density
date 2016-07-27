[![Server Density](images/Server-Density-Logo.png)](../../../server-density)
## Jelastic Server Density Add-on

This repository provides [Server Density](https://www.serverdensity.com/) add-on for Jelastic Platform.

**Server Density** is a server secure monitoring for your entire stack, out of the box. Flexible alerting, beautiful graphing, cloud integrations. Increase uptime by spotting negative trends in your data. Create and customise multiple views with different metrics, layouts and widgets.

**Type of nodes this add-on can be applied to**:
  - Application server (cp)
  - SQL Databases
  - noSQL Databases
  - Cache

### What it can be used for?
- Server monitoring tools<br/>
Increase uptime by spotting negative trends in your data. Create and customise multiple views with different metrics, layouts and widgets.
- Graphing Widget<br/>
Graph anything against anything and watch how things change over time. Build an understanding of what's normal… so you know when things aren't as normal.
- Elastic Graphs Widget<br/>
Plot all the metrics for devices or services matching a search term. This means we'll automagically display new devices and / or remove old ones for you. You're welcome.
- Alerts Widget<br/>
Alerts tend to need fixing - don't lose track of them. Our alerts widget allows you to see aggregated alerts for devices, groups or your entire infrastructure.
- Service Status Widget<br/>
Get an up to date feed of the status of your services from over 25 locations around the world. Is your website up? Is is loading quickly for your customers in Iceland?
- Cloud Status Widget<br/>
If things look like they're going wrong, you'll want to know about problems with your hosting provider. Get RSS feeds on the service status of the Cloud provider of choice.
- RSS Feed Widget<br/>
RSS is handy, pull any feed you want and show the it on your dashboard. It's a good idea to have status pages of some key services, or just something fun like XKCD.

Two initial options should be filled in:
- "Dashboard URL" like "{your doamin name}.serverdensity.io" to have access to the Server Density control panel.
- "API token" (32 chareacters).

### Deployment

In order to get this solution instantly deployed, click the "Get It Hosted Now" button, specify your email address within the widget, choose one of the [Jelastic Public Cloud providers](https://jelastic.cloud) and press Install.

[![GET IT HOSTED](https://raw.githubusercontent.com/jelastic-jps/jpswiki/master/images/getithosted.png)](https://jelastic.com/install-application/?manifest=https%3A%2F%2Fgithub.com%2Fjelastic-jps%2Fserver-density%2Fraw%2Fmaster%2Fmanifest.jps)

To deploy this package to Jelastic Private Cloud, import [this JPS manifest](../../raw/master/manifest.jps) within your dashboard ([detailed instruction](https://docs.jelastic.com/environment-export-import#import)).

For more information on what Jelastic add-on is and how to apply it, follow the [Jelastic Add-ons](https://github.com/jelastic-jps/jpswiki/wiki/Jelastic-Addons) reference.
Having problems? Have you checked these first:

* Have you made sure to [enable SQL Server authentication](http://bit.ly/1Kw3set)?
* Are you using FreeTDS 0.95.80 or later? Check `$ tsql -C` to find out.
* If not, please update then uninstall the TinyTDS gem and re-install it.
* Using Ubuntu? If so, you may have forgotten to install FreeTDS first.
* Doing work with threads and the raw client? Use the ConnectionPool gem?

If none of these help. Please make sure to report:

* What platform you are on. Windows, Mac, Ubuntu, etc.
* What version of FreeTDS you are using.

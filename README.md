# Accounting for russian Individual Entrepreneur with an income in USD
An Example of data warehouse on MS-SQL Server 2019 and an example of getting USD currency rates from the  http://cbr.ru/ REST-API service

1) Install SQL Server 2019 Developer 64 bit. https://www.microsoft.com/en-us/sql-server/sql-server-downloads
2) Install Microsoft Excel 2019 64 bit and
Microsoft Access Database Engine 2016 Redistributable. https://www.microsoft.com/en-us/download/details.aspx?id=54920
```
./AccessDatabaseEngine_X64.exe /passive
```
3) Install database and upload sample data from IncomeBook.xlsx
```
 ./db.ps1
```
4) Open Declaration.xlsm, enable vba.
5) Click refresh connection button

<p align="center">
  <img src="./screen/screen02.jpg" width="350" title=" Initial form">
</p>
6) Select year and click button Fill 3-НДФЛ
<p align="center">
  <img src="./screen/screen03.jpg" width="350" alt="accessibility text">
</p>




# Invoke-CsSQLcmd

Run a SQL query to all Front Ends in a pool, if no pool is specified, it will use the current computer to check if belongs to a Lync/Skype for Business Front End Pool and execute a SQL query.

<b>Parameters</b>
<ul>
    <li>PoolFqdn – Specifies the pool we want to run the SQL query.</li>
    <li>SQL Instance - If we want to query RTCLOCAL or LYNCLOCAL.</li>
    <li>SQLDatabase - Database where we want to execute the SQL query.</li>
    <li>SQLQuery - SQL query we want to execute.</li>
    <li>SQLFile - We can also create a file if the SQL query is complex.</li>
</ul>
<b>Release Notes</b>
<ul>
    <li>Version 1.0: 2019/10/09 - Initial release.</li>
    <li>Version 1.1: 2023/10/07 - Updated to publish in PowerShell Gallery.</li>
</ul>
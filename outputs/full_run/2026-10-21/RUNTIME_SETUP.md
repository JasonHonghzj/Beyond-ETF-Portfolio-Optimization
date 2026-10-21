# Native R runtime for the 2026-10-21 full run

R 4.6.1 for Windows x64 was downloaded from the official CRAN distribution:

- Installer: https://cran.r-project.org/bin/windows/base/R-4.6.1-win.exe
- Official MD5: https://cran.r-project.org/bin/windows/base/md5sum.R-4.6.1.txt
- Official installer MD5 verified: `7907f3a20ec8ec88cd0da279024b8e27`
- Official installation options: https://cran.r-project.org/bin/windows/base/rw-FAQ.html

Installation is isolated to this `runtime` directory and uses the current user.
No global PATH change, shortcut, R version registration, or file association was requested.
The installer creates its normal current-user Windows uninstall entry.
The scripts and installer log preserve the exact options used.

Required packages and their dependencies were installed as official CRAN Windows
binary packages into `runtime/library`, with the built-in package MD5 checks passing.
`native-package-versions.csv` and `package-install.log` capture package versions.

For each PowerShell invocation, set process-local values:

```powershell
$taskRuntime = 'C:\Users\acer\.codex\visualizations\2026\10\20\01a15b68-a85b-7921-b275-96f58bf1f438\full-run-2026-10-21\runtime'
$env:R_LIBS_USER = "$taskRuntime\library"
$env:LC_ALL = 'English_United States.utf8'
& "$taskRuntime\R-4.6.1\bin\Rscript.exe" --vanilla run.R
```

`functional-checks.log` confirms native training/prediction for XGBoost and random
forest, quadratic programming, maximum-clique enumeration, ADF testing, and reading
the 1,195-row 2330 workbook. These smoke checks establish runtime functionality;
the complete project run and model evaluation are recorded separately.

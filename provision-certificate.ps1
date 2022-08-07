Import-Certificate `
    -FilePath c:\vagrant\shared\tls\example-ca\example-ca-crt.der `
    -CertStoreLocation Cert:\LocalMachine\Root `
    | Out-Null

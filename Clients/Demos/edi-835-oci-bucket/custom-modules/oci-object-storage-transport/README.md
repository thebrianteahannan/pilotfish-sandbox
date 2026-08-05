# OciObjectStorageTransport

Custom PilotFish eiPlatform Transport (`com.pilotfish.eip.modules.oci.OciObjectStorageTransport`) that performs **signed OCI Object Storage PutObject** with the official OCI Java SDK.

## Build

```bash
docker build --target export -o type=local,dest=./dist .
cp dist/modules-oci-object-storage.jar ../../pilotfish/custom-lib/
```

The PilotFish demo image copies `pilotfish/custom-lib/*.jar` into `WEB-INF/lib`.

## Local emulator

Demo uses [floci-oci](https://github.com/floci-io/floci-oci) on `:4599` with throwaway credentials under `../../oci-config/`.

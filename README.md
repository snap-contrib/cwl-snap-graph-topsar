# Process SNAP GPT TopSAR graph using docker and the Common Workflow Language (CWL)

[![Project Status: WIP – Initial development is in progress, but there has not yet been a stable, usable release suitable for the public.](https://www.repostatus.org/badges/latest/wip.svg)](https://www.repostatus.org/#wip)

This repo provides a method to process Earth Observation data with the SNAP Graph Processing Tool (GPT) using docker and CWL.

With this method, the host machine does not have to have SNAP installed. 

CWL is used to invoke the SNAP `gpt` command line tool and deals with all the docker volume mounts required to process a Graph and EO data available on the host.

This repo contains a SNAP Graph for the TopSAR processing chain for a pair of Sentinel-1 SLC acquisitions.


## Requirements

### CWL runner

The CWL runner executes CWL documents. 

Follow the installation procedure provided [here](https://github.com/common-workflow-language/cwltool#install)

### Docker

The SNAP processing runs in a docker container so docker is required. 

Follow the installation steps for your computer provided [here](https://docs.docker.com/get-docker/)

If needed follow the additional steps described [here](https://docs.docker.com/engine/install/linux-postinstall/) to allow the CWL runner to manage docker as a non-root user.

## Getting started 

### Setting-up the container

Clone this repository and build the docker image with:

```console
git clone https://github.com/snap-contrib/cwl-snap-graph-topsar.git
cd cwl-snap-graph-topsar
docker build -t snap:latest -f .docker/Dockerfile .
```

Check the docker image exists with:

```console
docker images | grep snap:latest
```

This returns one line with the docker image just built.

Check if SNAP `gpt` utility is available in the container:

```console
docker run --rm -it snap:latest gpt -h
```

This dumps the SNAP `gpt` utiliy help message.

### Getting a pair of Sentinel-1 SLC acquistions

Download a pair of Sentinel-1 SLC acquisitions and unzip them.

### Preparing the input parameters for the CWL step

The CWL parameters file is a YAML file with an array of input directories pointing to the SAFE folders:

```yaml
snap_graph_ifg: {class: File, path: ./read-split-ifg.xml }
snap_graph_merge: {class: File, path: ./topsar-merge-write.xml}
primary: {'class': 'Directory', 'path': '/home/fbrito/Downloads/ifg/S1B_IW_SLC__1SDV_20210528T050419_20210528T050446_027100_033CC1_D1F1.SAFE' }
secondary: {'class': 'Directory', 'path': '/home/fbrito/Downloads/ifg/S1A_IW_SLC__1SDV_20210510T050500_20210510T050527_037821_0476C8_9B39.SAFE' }
subswath:
- IW1
- IW2
- IW3
```

Save this content in a file called `gpt-topsar-params.yml`.

### The SNAP Graphs

There are two graphs: 
- the first, `read-split-ifg.xml` processes a pair of SLC for a given subswath. The CWL documents will run three instances, one for each subswath
- the second, `topsar-merge-write.xml`, merges the three interferograms


The CWL file will instruct `gpt` to use the value passed as a command line argument, e.g.:

```yaml
inp2:
  inputBinding:
    position: 2
    prefix: -PinFileP=
    separate: false
    valueFrom: ${ return inputs.inp2.path + '/manifest.safe'; }
  type: Directory
```

### Run the SNAP graph with CWL in the container

```console
cwltool gpt-topsar.cwl gpt-topsar-params.yml
```

This will process the Sentinel-1 SLC acquisitions with an output as:

```console
INFO Resolved 'gpt-topsar.cwl' to 'file:///home/fbrito/work/cwl-snap-graph-topsar/gpt-topsar.cwl'
INFO [workflow ] start
INFO [workflow ] starting step node_1
INFO [step node_1] start
INFO [job node_1] /tmp/ucka8ag3$ docker \
    run \
    -i \
    --mount=type=bind,source=/tmp/ucka8ag3,target=/KpOtlZ \
    --mount=type=bind,source=/tmp/kxlwdgvx,target=/tmp \
    --mount=type=bind,source=/home/fbrito/work/cwl-snap-graph-topsar/read-split-ifg.xml,target=/var/lib/cwl/stge925f2e3-6e06-423a-8093-3f905b1b2df9/read-split-ifg.xml,readonly \
    --mount=type=bind,source=/home/fbrito/Downloads/ifg/S1B_IW_SLC__1SDV_20210528T050419_20210528T050446_027100_033CC1_D1F1.SAFE,target=/var/lib/cwl/stgcbfbf538-5acd-4fa7-b54d-b8bfacd7ada0/S1B_IW_SLC__1SDV_20210528T050419_20210528T050446_027100_033CC1_D1F1.SAFE,readonly \
    --mount=type=bind,source=/home/fbrito/Downloads/ifg/S1A_IW_SLC__1SDV_20210510T050500_20210510T050527_037821_0476C8_9B39.SAFE,target=/var/lib/cwl/stgcfd9ff72-8883-49fc-9bb9-8607a99c018e/S1A_IW_SLC__1SDV_20210510T050500_20210510T050527_037821_0476C8_9B39.SAFE,readonly \
    --workdir=/KpOtlZ \
    --read-only=true \
    --user=1000:1000 \
    --rm \
    --env=TMPDIR=/tmp \
    --env=HOME=/KpOtlZ \
    --cidfile=/tmp/zb565z_k/20210618091102-293287.cid \
    --env=PATH=/srv/conda/envs/env_snap/snap/bin:/usr/share/java/maven/bin:/usr/share/java/maven/bin:/opt/anaconda/bin:/opt/anaconda/condabin:/opt/anaconda/bin:/usr/lib64/qt-3.3/bin:/usr/share/java/maven/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin \
    --env=PREFIX=/opt/anaconda/envs/env_snap \
    snap:latest \
    gpt \
    -PoutFile=IW_ifg.dim \
    /var/lib/cwl/stge925f2e3-6e06-423a-8093-3f905b1b2df9/read-split-ifg.xml \
    -PinFileP=/var/lib/cwl/stgcbfbf538-5acd-4fa7-b54d-b8bfacd7ada0/S1B_IW_SLC__1SDV_20210528T050419_20210528T050446_027100_033CC1_D1F1.SAFE/manifest.safe \
    -PinFileS=/var/lib/cwl/stgcfd9ff72-8883-49fc-9bb9-8607a99c018e/S1A_IW_SLC__1SDV_20210510T050500_20210510T050527_037821_0476C8_9B39.SAFE/manifest.safe \
    -PsubSwath=IW1
INFO: org.esa.snap.core.gpf.operators.tooladapter.ToolAdapterIO: Initializing external tool adapters
INFO: org.esa.s2tbx.dataio.gdal.GDALVersion: GDAL not found on system. Internal GDAL 3.0.0 from distribution will be used. (f1)
INFO: org.esa.s2tbx.dataio.gdal.GDALVersion: Internal GDAL 3.0.0 set to be used by SNAP.
INFO: org.esa.snap.core.util.EngineVersionCheckActivator: Please check regularly for new updates for the best SNAP experience.
INFO: org.esa.s2tbx.dataio.gdal.GDALVersion: Internal GDAL 3.0.0 set to be used by SNAP.
Executing processing graph
INFO: org.hsqldb.persist.Logger: dataFileCache open start
WARNING: org.esa.s1tbx.sar.gpf.orbits.ApplyOrbitFileOp: No valid orbit file found for 28-MAY-2021 05:03:12.000000
Orbit files may be downloaded from https://scihub.copernicus.eu/gnss/odata/v1/
and placed in /tmp/.snap/auxdata/Orbits/Sentinel-1/POEORB/S1B/2021/05
...
```


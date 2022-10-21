# Build u-boot for Spotify Car Thing

NOTE: I haven't dug into their research yet to reproduce their binaries, but [this repo](https://github.com/frederic/superbird-bulkcmd) looks like they managed to get root access! I will get more info from them and update this repo soon.

WIP - This battlestation is NOT currently operational.

I am still working through the details to get the complete bootable image created.

Right now, u-boot builds, and we can assemble and sign/encrypt the image, BUT it is being done using the amlogic firmware blobs for the `u200` dev board (same SoC), so... well it is not bootable on the Car Thing at all.

I have uploaded this project in its current state with the hope that others will find it useful, and maybe even figure out how to make it work.

## What is next? 
We need to find the firmware blobs specific to the `superbird` device in order to generate a working image.

I found [some g12a firmware blobs](https://github.com/LibreELEC/amlogic-boot-fip/tree/master/u200) for the u200 development board, which is the reference hardware for S905D2.
This script has been updated to use those blobs to generate the final image, howver I get the same response on the serial console: `CHK:1F;#`.

I might be chasing the wrong rabbit here, it is quite likely that the device simply has secure boot properly setup so that it only accepts binaries signed by Spotify.


## How to use this

My test machine is x86_64 running Ubuntu 22.04.1 LTS. 

Almost everything here is contained in only two files: `Dockerfile` and `makeimage.sh`. 
The `docker-compose.yml` is not particularly necessary, just how I am used to working.

Please note that `docker-compose.yml`, `clean.sh`, and `test.sh` all reference the image by name: `bishopdynamics/car-thing-builder:latest`, which is something you should probably change.

To build the image:
* if you have not already done so, install docker: `sudo apt-get install docker docker-compose`
* run `./build.sh` to create the docker container
* run `./test.sh` which will run the container, executing `makeimage.sh` to do the work.
* resulting image files can be found: `./bin/`

The script `test.sh` takes an optional argument, the entrypoint. So you can start a container without running the build script by doing: `./test.sh /bin/bash`, and then run the script at `/makeimage.sh`

## How to boot this

This does not actually boot at the moment, but this is how to do it anyway.

You need to boot the device in maskrom mode, by holding all four buttons (all except pwr button on far right, recessed a little) at the top while powering on the device. If you have a serial console hooked up you will see this upon boot:

`G12A:BL:0253b8:61aa2d;FEAT:F0F821B0:12020;POC:D;RCY:0;USB:0;`

Check out [this page](https://wiki.radxa.com/Zero/dev/maskrom#Install_required_tools)
to install `pyamlboot`. Then you can use `boot-g12.py` to sideload the image like so:

`boot-g12.py ./bin/u-boot.bin`

or try what I think is the right one for USB maskrom: `boot-g12.py ./bin/u-boot.bin.usb.bl2`

On the serial console you will see `CHK:1F;#` which I *think* means signature check error, or maybe checksum error. 
Regardless, it does not boot.

## History
Spotify recently discontinued their "Car Thing" product, which is a small device intended to be mounted on
your dashboard, to control spotify for users who do not have Android Auto or Apple Car Play. 

The device went on clearance for $30, and so we are all interested to see if we can do more fun things with it instead.

The device is powered by an Amlogic S905D2, which is very similar to that found in the Radxa Zero. 
This gives us somewhere to start.
However, the similarities end there, as the Car Thing has a different set of peripherals.

The u-boot source [found here](https://github.com/spsgsb/uboot) appears to be Spotify's own source for u-boot. 
The device codename appears to be `superbird`, and it looks like it is shared with another device that might be built into a TV.

From the device tree, it looks like the only real difference between "Car Thing" and "TV Thing" (I just made that up) is presence of HDMI input, and IR receiver.
Of course, the linux kernel and userland are also probably different.

In this repo, we attempt to build a u-boot for the Car Thing, loosely following the [instructions here](http://wiki.loverpi.com/faq:sbc:libre-aml-s805x-howto-compile-u-boot) 

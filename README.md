# Carnet: Bureaucracy for Cargo

> **IMPORTANT NOTICE**:   Carnet is pre-alpha software. Sandboxing works. 
> Crate authentication is not ready yet. Identity and key 
> life-cycle management are WIH.

Carnet is a small tool that imposes additional security constraints 
on Rust's official package manager, Cargo. This tool aims to prevent 
or otherwise limit the damage malicious crates can cause. 
                     
Carnet imposes two types of security constraints on Cargo:
    
1. It can isolate Cargo to a separate system-enforced 
   sandbox, only allowing access to a limited subset of 
   system resources.

2. It can authenticate crates before allowing Cargo to 
   operate on them. (This feature is incomplete and should 
   not be used yet.)

Carnet is meant as a temporary solution until Cargo gains the ability to 
impose these constraints on its own.

## Installing & Updating

If your system is compatible with the FHS standard, you can install 
Carnet system-wide by downloading this repository and running the 
following command at the root of the repository: 


```sh
sudo install ./carnet /usr/local/bin/carnet
```

Alternatively, you can install Carnet to your user's `bin` directory
by running the following command in the root of this repository if 
your system is configured to respect the XDG standard:

```sh
install ./carnet ~/.local/bin
```

Carnet requires the following dependencies to be installed on your 
system:

- A modern version of GNU Bash (>= 4.4, 2016)
- GNU Core Utilities
- Bubblewrap (`bwrap`)
- OpenSSL CLI Tool (`openssl`)
- Tiny C Compiler (`tcc`)


## Using Carnet 
    
Carnet can be used in place of Cargo, transparently accepting all
its arguments:

```sh
carnet test
carnet build --release
```

In both the commands above, Carnet will first verify the 
authenticity of the crate and then run the corresponding cargo 
command in a restrictive sandbox (unless configured otherwise). 
This sandbox prevents Cargo from accessing the network, most of 
the user's home directory, most of the filesystem, and so on 
by default.

Sandbox restrictions can be relaxed easily and can even be disabled
entirely by simply passing the appropriate flag to Carnet:

```sh
carnet --unsandbox-network     ...
carnet --unsandbox-cargo-home  ...
carnet --unsandbox-processes   ...
carnet --unsandbox-session     ...
carnet --unsandbox-filesystem  ...
... and so on.
```

In addition to general flags that act on entire resource classes,
Carnet can also expose individual files and directories within 
the sandbox via the flags `--carnet:ro-paths` and 
`--carnet:rw-paths`.

To avoid ambiguity, flags intended for Carnet can be prefixed 
with `carnet:` while flags intend for Cargo can be prefixed with 
`cargo:`. If both Carnet and Cargo accept the same flag and 
prefixes are not used, the handling of this flag is unspecified. 
The following example illustrates the use of both prefixes:

```sh
carnet --carnet:unsandbox-network test --cargo:release
```

Both the sandboxing of Cargo and the automatic verification of crates 
can be disabled, for a single invocation or persistently, through the 
use of the appropreate flag or by disabling the feature in Carnet's 
configuration settings:

```sh
carnet --disable-sandbox       ...
carnet --disable-verification  ...

carnet disable sandbox
carnet disable verification
```

Run `carnet carnet:help` or `carnet --carnet:help` for more 
information.


## History & Future Plans

We originally wrote this version of Carnet to only serve as a 
prototype for when we wanted to implement Carnet more robustly 
(in Rust). However, we ultimately decided against this approach and 
published Carnet as-is. Our decision was in part because we couldn't 
guarantee when this rewrite would occur. We also hope to gather 
enough feedback to help us make a better Carnet when the rewrite 
eventually takes place.


## Feedback is Important

Since we don't include any telemetry in Carnet, we rely on your 
feedback to gauge how successful this project is. If you use Carnet 
and don't mind sharing this fact publicly, let us know by leaving a 
comment on the Github issue here: 
https://github.com/kutometa/carnet/issues/3

Alternatively, you can let us know by sending a short email to 
support@ka.com.kw.


## Contributing

Please see `CONTRIBUTING.md` in the root of this repository.

    
## Support & Licensing

Official commercial support and custom licensing are available 
directly from the authors of this software. Please send your 
inquiries via any of our official communication channels. 

Our communication channels are listed at: 
https://www.ka.com.kw/en/contact


## Copyright

#### Copyright © 2021 Kutometa SPC, Kuwait

Unless expressly stated otherwise, this work and all related material 
are made available to you under the terms of version 3 of the GNU
Lesser General Public License (hereinafter, the LGPL-3.0) and the
following supplemental terms:

1. This work must retain all legal notices. These notices must 
   not be altered or truncated in any way.

2. The origin of any derivative or modified versions of this work
   must not be presented in a way that may mislead a reasonable 
   person into mistaking the derive work to originate from Kutometa 
   or the authors of this work.

3. Derivative or modified versions of this work must be clearly 
   and easily distinguishable from the original work by a 
   reasonable person.
   
4. Unless express permission is granted in writing, The name of 
   the original work may not be used within the name of any 
   derivative or modified version of the work.

5. Unless express permission is granted in writing, Trade names, 
   trademarks, and service marks used in this work may not be 
   included in any derivative or modified versions of this work.
   
6. Unless express permission is granted in writing, the names and
   trademarks of Kutometa and other right holders may not be used
   to endorse derivative or modified versions of this work.

7. The licensee must defend, indemnify, and hold harmless 
   Kutometa and authors of this software from any and all 
   actions, claims, judgments, losses, penalties, liabilities, 
   damages, expenses, demands, fees (including, but not limited 
   to, reasonable legal and other professional fees), taxes, and 
   cost that result from or in connection with any liability 
   imposed on Kutometa or other authors of this software as a 
   result of the licensee conveying this work or a derivative 
   thereof with contractual assumptions of liability to a third 
   party recipient.

Unless expressly stated otherwise or required by applicable law, 
this work is provided AS-IS with NO WARRANTY OF ANY KIND, 
INCLUDING  THE  WARRANTY  OF MERCHANTABILITY AND FITNESS FOR A
PARTICULAR PURPOSE. Use this work at your own risk.

This license agreement is governed by and is construed in accordance 
with the laws of the state of Kuwait. You must submit all disputes 
arising out of or in connection with this work to the exclusive 
jurisdiction of the courts of Kuwait.

You should have received a copy of the LGPL-3.0 along with this 
program; if not, visit www.ka.com.kw/en/legal, write to 
legal@ka.com.kw, or write to Kutometa SPC, 760 SAFAT 13008, Kuwait.


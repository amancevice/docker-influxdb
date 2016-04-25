# InfluxDB Cluster Setup

A simplistic approach to configuring and starting InfluxDB cluster nodes.

The configuration of InfluxDB on startup is determined by two key environmental variables, `INFLUXD_CONFIG` & `INFLUXD_OPTS`, and the `CMD` passed into the Docker invocation.

The variable `INFLUXD_CONFIG` represents the path to the configuration file that `influxd` uses to bring up the node.

Additional startup options can be stored in the `INFLUXD_OPTS` variable (this is optional), or by passing them into the Docker `CMD` invocation.


## Influxd Configuration

The default behavior of the node is to create a new configuration file by executing the `influxd config` command at startup and piping the contents to `/etc/influxdb/influxdb.conf`. Altering the value of `INFLUXD_CONFIG` will change the location of this generated file.

Values in the generated file can be patched/overridden through `ENV` variables or by mounting your own configuration.


### Patching/Overriding defaults with a partial config

As of InfluxDB `0.10.0` the `influxd config` command accepts a `-config` option to submit a partial config that will overwrite the default generation. Mounting a custom partial config can be used to patch defaults without writing an entire config file.

Consider the following partial custom config:

```ini
[meta]
  dir = "/mnt/db/meta"

[data]
  dir = "/mnt/db/data"
  wal-dir = "/mnt/influx/wal"

[hinted-handoff]
  dir = "/mnt/db/hh"
```

Mounting this file to `/root/influxdb.conf.patch` when creating/starting the container will patch the default config with the values provided. Partial custom configurations can be mounted elsewhere but the value of the `ENV` variable `INFLUXD_PATCH` must be changed in addition to reflect the non-standard location of the custom partial file.


### Patching/Overriding Defaults with `ENV`

If it is the case that *most* of the default configuration is acceptable, values can be patched piecemeal by defining `ENV` variables using the naming convention `INFLUX___<section>___<option>=<value>`. In many cases, passing `ENV` variables is easier than mounting custom configs as well. Passing `ENV` variables in this manner overrides custom partial files as described above.

The variable must start with the string `"INFLUX"`, followed by three underscores (`___`), the name of the configuration section, three more underscores (`___`), and the name of the option.

If the section or option name contains an underscore (`_`), replace it in the `ENV` name with two underscores (`__`). Replace dashes (`-`) with a single underscore (`_`).

Take the following configuration section:

```ini
[continuous_queries]
  ...
  compute-no-more-than = "2m0s"
```

Override `compute-no-more-than` by setting the `ENV` variable:

```bash
INFLUX___CONTINUOUS__QUERIES___COMPUTE_NO_MORE_THAN="5m0s"
```

Which yields:

```ini
[continuous_queries]
  ...
  compute-no-more-than = "5m0s"
```

**Suggestion:** Store your patched options in an Envfile to make container invocation simpler.


### Mounting A Custom Configuration

Instead of patching individual options, an entire configuration can be mounted into the container. Ensure that the location of the mounted config is reflected in the `INFLUXD_CONFIG` variable:

```bash
docker run --rm --interactive --tty \
    --env INFLUXD_CONFIG=/influxdb/influxdb.conf \
    --volume $(pwd)/example:/influxdb \
    amancevice/influxdb-cluster
```

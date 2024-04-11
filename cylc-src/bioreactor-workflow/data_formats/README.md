# CONSIDERATIONS FOR DATA FORMATTING

Default formats used between tasks of the workflow are flat `.csv` files, where data repetition is minimized.

Some of them (notably ***features.csv*** and ***matches.csv***) contain timestamped data, with the datetime being the start of the MS run (one of each is generated from any `.raw` MS run file).
This formatting is based on how Time Series Databases (e.g. InfluxDB) organize data.

The others files (***molecules_db.csv***) have data organized in a more classical way, with the first column containing a unique identifier.

Applying [InFluxDB terminology](https://docs.influxdata.com/influxdb/v2/reference/key-concepts/data-elements/#sample-data) to ***features.csv*** :
- features is the Measurement,
- `datetime` is the Timestamp,
- `mz`, `intensity`, `purity` and `centrality` are Fields,
- `instrument_id` and `polarity` are Tags,
- each line is a Point.




## molecule_db.csv
- Columns are named following Skyline conventions.
- `Molecule ID` values should be uniques.
- in ***molecules_db.csv***, adducts/fragments/etc should share a same `Metabolite ID`, but different `Molecule ID`. A `Molecule ID` is a MS signal, a `Metabolite ID` is in biological context (and in the context of a SBML metabolic network file).
- solvant molecules can be given a fake `Metabolite ID`, as for 13C standards.
- `Ref Mol ID` should match an ID from `Molecule ID`. It is used for relative quantification.
- `Coeff A` and `Coeff B` are used for absolute quantification (y=Ax+B).

## features.csv

TODO

## matches.csv

TODO
`delta_mz` : difference between `peak_mz` and the `Precursor m/z` from the database.
`co_matches` : number of `Molecule ID`s from the database that also matched to the same `peak_mz`.
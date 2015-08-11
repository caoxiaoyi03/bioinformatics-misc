TO DO:

  * If an interval extends right to the end of a chromosome, the fasta sequence cannto be fetched with default settings because --slop will extend the region beyond the chrom and bedtools skips the feature. (Temp fix: set --slop 0 in such cases)

  * If the index of a bam file is not found, throw a friendly message rather than the cryptic one currently thrown

  * Fixed ~~Error if -i files has no overlap with -b~~
  * Fixed (use `String.equals()` instead of `==`) ~~Error with pileup line `echo -e "chr10\t57687705\tN\t2\tC^-C"`~~



# Introduction  & Description #


---

![http://bioinformatics-misc.googlecode.com/svn/wiki/images/chr18_702863_703208.png](http://bioinformatics-misc.googlecode.com/svn/wiki/images/chr18_702863_703208.png)

---


**genomeGraphs** produces coverage files and plots for one or more input files
at the intervals specified in a bed file. Plots are written in pdf format, one per
region or they can be concatenated in a single file.

Plots can be annotated according to one or more GTF, BED or bed-like files and decorated with the individual
nucleotides if a corresponding reference FASTA file is provided.

In contrast to most genome browsers (IGV, IGB etc.) `genomeGraphs`
is deliberately designed to be avoid any graphical user interface so that it can be
included in script and pipelines and can be run on enviroments not designed to
support GUIs (e.g. computer farms). The graphical output can be customized via
several options passed to R.

Some implementation details: The heavy duty task of counting nucleotides at each
position is performed by `samtools mpileup`so it is reasonably fast. Interval
operations are executed by [pybedtools](http://pythonhosted.org/pybedtools/). If
the size of the interval exceeds a set limit (`--nwinds`), the interval is divided
in equally sized windows and the nucleotide counts averaged by window (See genomeGraphs\_docs#Example\_3:_Re-plotting)._

Plotting is done by the [R](http://cran.r-project.org/) standard library.

**Remember** If you save the intermediate output directory (`--tmpdir`), you can replot
the data without going through the expensive operation of counting depth and bases.

# System Requirements & Installation #

`genomeGraphs` lives at http://bioinformatics-misc.googlecode.com/svn/trunk/genomeGraphs.
A package to download is at [_in prep_].

All the components that make `genomeGraphs` are freely available from
the net.

  * **python 2.7** Version 2.5+ should do, 3.x not yet.
  * [samtools 0.1.18](http://samtools.sourceforge.net/) other reasonably new versions should do.
  * [R](http://cran.r-project.org/) (Actually `Rscript`) to be found on your `$PATH`
  * **Linux/Unix** Windows might be working via Cygwin (see also [pybedtools](http://pythonhosted.org/pybedtools/main.html)).

## Required python packages ##

  * [argparse](http://docs.python.org/dev/library/argparse.html) Already included in python 2.7 standard library
  * [pybedtools](http://pythonhosted.org/pybedtools/)
  * [PyPDF2](https://pypi.python.org/pypi/PyPDF2) _Optional_: Only used to concatenate all PDF files in a single one (`--onefile`).

## Installation ##

Assuming the requirements above are satisfied, download and install `genomeGraphs` like any other python package.

```
tar zxvf genomeGraphs-x.x.x.tar.gz
cd genomeGraphs-x.x.x

## For a system-wide installation (requires root access):
python setup.py install --install-scripts /usr/local/bin/

## For a user-based installation (no need of root access):
python setup.py install --install-scripts $HOME/bin/ --user 
```

Use the `--install-scripts` option to put the executable script `genomeGraphs` in a directory of your choice, e.g. one on your `PATH`.

# Accepted input #

### Files to plot ###

File passed to **`--ibam/-i`** option can be:

  * **`bam`** files _sorted_ and _indexed_ (see below how to). File extension must be `.bam`

  * **`bedGraph`** files. Extension must be `.bedGraph`

  * **`BED/GTF/GFF`** format. BED files must be tab separated, no header lines, with at least three columns for chrom, start and end position.

These files can be listed one by one, using glob (e.g. `-i *.bam *.bed`) or via `stdin` e.g.
```
genomeGraphs -i *.bam -b ...
## Or
ls *.bam | genomeGraphs -i - -b ...
```

### Region files ###

The file specifying which regions should be plotted (**`--bed/-b`** option) must be:

  * **`BED/GTF/GFF`** format. If present, the value in the 4th column of the bed files is used as feature name (e.g. gene name).

Regions can be read from `stdin` e.g.

```
cat actb.beb | genomeGraphs -b - -i ...
## Or
echo "chr1 0 1000" | genomeGraphs -b - -i ...
```

### Additional files ###

The reference sequence file (**`--fasta/-f`**) must be in standard FASTA format.

The extension of the input files determine how plots are produced: bam files are shown as read pileups, bedgraphs as profiles of the fourth column, which therefore has to be numeric. bed, gtf and any other file (in bed format no matter the extension) are shown as annotation.

With the exception of BAM and FASTA, input files can be gzip'd and in this case the extension must end in `.gz` (e.g. `myfile.bedGraph.gz`).

See also [UCSC](https://genome.ucsc.edu/FAQ/FAQformat.html) for description of file formats.

_MEMO_ You can sort and index a bam file with samtools (http://samtools.sourceforge.net/):

```
samtools sort myfile.bam myfile_sort
samtools index myfile_sort.bam
```

# Description of output #

Intermediate output files, including the R script used to generate the plots,
can be saved for future inspection. The following files are generated for **each**
bed interval:

  * `*.mpileup.bed.txt`
> > Coverage and nucleotide counts (or rpm) at each postion in the interval
  * `*.grp.bed.txt`
> > Coverage and nucleotide counts (or rpm) averaged by equally sized windows
  * `*.seq.txt`
> > Base at each position in the interval (if a fasta file is provided (`--fasta`) and
> > the region size does not exceed the requested limit (`--max_fa` option) )
  * `*.annot.txt`
> > Annotation file with GTF features intersected by this bed interval.
  * `*.R`
> > R script to produce the PDF files.
  * `*.pdf`
> > PDF file of the plots

Files are named according to the bed interval from which they come (`chrom_start_end[_name]` e.g. _chr7\_5566644\_5570292\_ACTB.pdf_).

For example, the following execution
```
genomeGraphs --ibam *.bam genes.gtf.gz --bed actb.bed --rpm 
```

will plot the coverage of all the bam files in the current directory at the
postions specified in the bed file `actb.bed`. It will also add the postions of
exons and CDSs as reported in `genes.gtf.gz`. with `--rpm` coverage is reported as
_reads per million_.

Keep in mind that **each** interval (row) in the input bed file produces 5 or 6 files.
Consider this before passing the whole of human refseq to coverge\_sscreenshots.


---

![http://bioinformatics-misc.googlecode.com/svn/wiki/images/chr7_5566757_5566829_ACTB.jpg](http://bioinformatics-misc.googlecode.com/svn/wiki/images/chr7_5566757_5566829_ACTB.jpg)

Example output from `genomeGraphs` with annotation and colour code nucleotide counts.

---


# Usage & Examples #

The source directory contains data files for testing and examples
```
cd example
cat actb.bed
    chr7	5566757	5566829	ACTB
    chr7	5566755	5567571	ACTB
    chr7	5566644	5570292	ACTB
```
To see all the available options and get help
```
genomeGraphs -h
```

## Example 1: Vanilla ##

The minimum necessary to produce coverage plots is bam files **sorted** and **indexed** and
a bed file of positions to capture. (In fact, bam files are not necessary if you want to re-plot
existing data, see below)
```
genomeGraphs -i bam/ds0*.bam -b actb.bed
```
Default settings plot raw read counts scaling each region to the maximum of all the
files.

## Example 2: Adding annotation ##

Now, rescale coverage to reads per million (RPM) and set the y-axis to 40000 rpm. Also add annotation
of exons and CDSs in the target intervals and report the underlying nucleotide sequence. Sequence is
reported if the target region is smaller than `--max_fa` bp. Finally, concatenate the files in a single pdf (requires `PyPDF2 <https://pypi.python.org/pypi/PyPDF2/>`_package)
```
genomeGraphs -i bam/ds0*.bam \
    -b actb.bed \
    -g genes.gtf \
    -f chr7.fa \
    --onefile actb_pdf/actb.pdf \
    --rpm \
    --ylim 40000 \
    --tmpdir wdir
```
Intermediate files have been saved for future use under directory `wdir`._

## Example 3: Re-plotting ##

Since computing coverage can be expensive, we don't need to do it again if all we
want is to change the graphical output. If we saved the intermediate output files
from a previous run by seeting `--tmpdir`, we can re-use them with option `--replot`
and change the graphical settings to our liking.
```
genomeGraphs -b actb.bed --tmpdir wdir --rpm \
    --col_cov pink \
    --pwidth 12 \
    --psize 12 \
    --cex_seq 0.6 \
    --col_seq darkred \
    --onefile actb_pdf/actb-2.pdf \
    --replot
```

Note that it is no longer necessary to give the bam, gtf, and fasta files. All we need
to `replot` is the original bed file, possibly with some rows removed if
we don't want them anymore, and the working directory where the previously
generated files are  (`--tmpdir`).


---

![http://bioinformatics-misc.googlecode.com/svn/wiki/images/chr7_5566644_5570292_ACTB.jpg](http://bioinformatics-misc.googlecode.com/svn/wiki/images/chr7_5566644_5570292_ACTB.jpg)

Example of RNA-Seq data for the ACTB gene with colour coded samples (`--bg` opt)
and coarse resolution (`--nwinds` opt).

---


# Some tips #

### Supressing features ###

If you find some of the graphics features annoying, here's how to turn them off:

| `--col_text_ann NA` or `--col_text_ann transparent`    | Don't print the names of bed features (_e.g._ genes in annotation tracks) |
|:-------------------------------------------------------|:--------------------------------------------------------------------------|
| `--col_track NA`                                       | Don't draw coverage bars (_i.e._ the area under coverage profiles)        |
| `--col_track_rev NA`                                   | Don't use a different colour for reads on reverse strand                  |
| `--col_line NA`                                        | Don't add border profile to coverage tracks                               |
| `--bg NA`                                              | Don't use any background for plot area                                    |
| `--fbg NA`                                             | Don't use any background for figure area                                  |
| `--grid NA`                                            | Don't draw grid lines                                                     |
| `--col_mark NA`                                        | Don't plot the triangles marking the extremes of the input bed region     |
| `--nwinds 1000000`                                     | Don't group read counts or score from `--ibam` in windows (could generate huge pdf files!) |
| `--slop 0`                                             | Don't extend `--bed` features for plotting. Plot them exactly as they are |
| `--maxseq 0`                                           | Don't print sequence at the bottom of the plotting figure                 |
| `--col_seq NA`                                         | Same as `--maxseq 0`                                                      |
| `--names ''`                                           | Don't print the name (e.g. the file name) on each plot                    |
| `--col_names NA`                                       | Same as `--names ''`                                                      |
| `--no_col_bases`                                       | Don't colour individual nucleotides even if the region span is < maxseq   |
| --title ''                                             | Don't print the figure title                                              |
| `-o /dev/null/`                                        | Don't save the pdf output (if `--tmpdir` is None nothing is saved)        |

### Colours ###

The colours passed to `genomeGraphs` are in turn passed to R verbatim,
therefore any R colour name or format is valid. R understands most English names of
colours (_red_, _lightblue_ etc.) as well as the RGB representation (e.g. `#0000FF`, `00255`).
See this nice [chart](http://research.stowers-institute.org/efg/R/Color/Chart/ColorChart.pdf)
for many colour options.

Transparent colours often show up better in graphics. To add transperency to an R colour, use
this function (credit [stackoverflow](http://stackoverflow.com/questions/8047668/transparent-equivalent-of-given-color))

```
makeTransparent<-function(someColor, alpha=100){
    newColor<-col2rgb(someColor)
    apply(newColor, 2, function(curcoldata){rgb(red=curcoldata[1], green=curcoldata[2],
    blue=curcoldata[3],alpha=alpha, maxColorValue=255)})
}
makeTransparent('red', 50) >>> '#FF000032'
```

### Converting PDF ###

To convert PDF images to jpg you can use the [convert](http://www.imagemagick.org/script/convert.php) tool from [ImageMagick](http://www.imagemagick.org/script/index.php)
like this:
```
convert -density 300 chr7_5566757_5566829_ACTB.pdf chr7_5566757_5566829_ACTB.jpg
```

To convert a multi-page pdf as produced by `--onefile` to individual jpeg or png use:

```
convert -density 300 switch_regions.ymax.pdf[0-2] region_%0d.png
```

Using the syntax `[0-2]` only the first 3 pdf pages will be converted. The syntax `%0d` will number output files with a leading zero.

### Opening pdf from shell ###

The utility **`gnome-open`** should be present on most Linux systems. The following

```
gnome-open chr1_43824445_43824745.pdf
```

will pop-up an X11 window with the pdf image.

One Macs use:

```
open chr1_43824445_43824745.pdf
```

# Bugs & Gotchas #

  * Bam files are parsed via `samtools mpileup` which is hard-coded to skip reads marked as duplicate. If you have such reads and you want to count them, either unset the 1024 flag or look at this suggestion http://seqanswers.com/forums/showthread.php?t=22752.

  * Non exsistant files passed to `-i` are silently ignored. This is intentional

  * Number of tracks is restricted to <200. This is due to R function `layout()` having a limit of 200 panels. (TODO: Change to `grid.layout()`)
#!/home/berald01/.local/bin/python

"""
Execute bamqc.py on all the bam files under BAMQCDIR (searched recursivley)
Output files sent to BAMDIR.

bamqc.py is executed on lustre using bsub.
"""

import subprocess
import os

BAMQCDIR= '/lustre/sblab/berald01/bamqc' ## dir where output files will be
BAMDIR= '/lustre/sblab/berald01' ## Top dir where to serach for bams
LOCALHOST= '143.65.172.155' ## Where the output of bamqc will be scp'd
LOCALDIR= '/tmp/'

p= subprocess.Popen('find %s' %(BAMDIR), shell= True, stdout=subprocess.PIPE)
allfiles= p.stdout.read().strip()
allfiles= allfiles.split('\n')
bamfiles= [x for x in allfiles if x.endswith('.bam')]
if not os.path.exists(BAMQCDIR):
    os.makedirs(BAMQCDIR)

for bam in bamfiles:
    bamqc_out= os.path.join(BAMQCDIR, os.path.splitext(os.path.split(bam)[1])[0] + '.bamqc.tsv')
    bamqc_log= os.path.join(BAMQCDIR, os.path.splitext(os.path.split(bam)[1])[0] + '.bamqc.log')
    jobname= 'jobbamqc_' + bam
    cmd= 'bsub -R "rusage[mem=1024]" -J %s -o %s "bamqc.py --nograph --noheader -i %s -o %s"' %(jobmame, bamqc_log, bam, bamqc_out)
    p= subprocess.Popen(cmd, shell= True)

cmd= """bsub -R "rusage[mem=1024]" -w jobbamqc_* '
cat %(bamqcdir)s/*.bamqc.tsv > %(cat_bamqc)s;
scp %(cat_bamqc)s %(localhost)s:%(localdir)s;
ssh %(localhost)s "echo \\"SELECT upload_bamqc('%(bamqc_local)s');\\" > %(localdir)s/bamqc_import.sql"
'
""" %{'bamqcdir':BAMQCDIR.rstrip('/'), 'cat_bamqc': os.path.join(BAMQCDIR, 'bamqc.tsv'), 'localhost':LOCALHOST, 'localdir': LOCALDIR, 'bamqc_local': os.path.join(LOCALDIR, 'bamqc.tsv')}
p= subprocess.Popen(cmd, shell= True)
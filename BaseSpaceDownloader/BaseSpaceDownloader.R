#! /usr/bin/env Rscript

VERSION<- '0.1.0a'
APP_NAME= 'Get FASTQ files' # App name to get fastq files

done<- suppressWarnings(suppressMessages(require(BaseSpaceR)))
if(done == FALSE){
    cat('Please install the "BaseSpaceR" package.\n')
    cat('See http://master.bioconductor.org/packages/release/bioc/html/BaseSpaceR.html\n\n')
    quit(save= 'no', status= 1)
}

getBasespaceToken<- function(app_name= APP_NAME, x= '~/.basespace_login'){
    # x:
    #   Log in file to read and get the access token
    # app_name:
    #   Name of App to get Access to.
    #
    # Login file (~/.basespace_login) is tab separated with two columns named:
    # app_name, access_token.
    # 
    # For example (| = tab):
    # -----------------------------------
    # app_name        | access_token    
    # Get FASTQ files | dd9d20...59c5b43
    # -----------------------------------
    xf<- read.table(x, sep= '\t', header= TRUE, stringsAsFactors= FALSE)
    if(app_name %in% xf$app_name == FALSE){
        stop(sprintf("\n\nApp name '%s' not found!\n\n", app_name))
    }
    token<- xf$access_token[which(xf$app_name == app_name)]
    if(length(token) > 1){
        stop(sprintf('More than one token found for App %s', app_name))
    }
    return(token)
}

getFastqFromBaseSpace<- function(
    proj_id,
    accessToken,
    dest_dir= '.' ,
    regex= '.*\\.gz$',
    echo= FALSE,
    verbose= TRUE){
    # Download fastq files for project ID from BaseSpace.
    # MEMO: Fastfile names might be slightly dofferent from BaseSpace. E.g.
    # proj_id:
    #   Project ID. You can get this from extracted project URL
    # dest_dir:
    #   Destination dir. Fastq will be in Data/....
    # accessToken:
    #   Access token. If NULL, try to read it from '~/.basespace_login' where
    #   the app line 'Get FASTQ files' is expected to be found.
    # regex:
    #   perl regexp to grep only these file names.
    # echo:
    #   If TRUE, only show which files would be downloaded.
    # Returns:
    #   Vector of downloaded files
    files<- vector()
    aAuth<- AppAuth(access_token = accessToken)
    myProj <- listProjects(aAuth)
    selProj <- Projects(aAuth, id = proj_id, simplify = TRUE) 
    sampl <- listSamples(selProj, limit= 1000)
    inSample <- Samples(aAuth, id = Id(sampl), simplify = TRUE)
    for(s in inSample){ 
        f <- listFiles(s)
        if( grepl(regex, Name(f), perl= TRUE) ){
            files<- append(files, f)
            if(verbose){
                print(f)
            }
            if(!echo){
                getFiles(aAuth, id= Id(f), destDir = dest_dir, verbose = TRUE)
            }
        }
    }
    return(files)
}


# END_OF_FUNCTIONS <- Don't change this string it is used to source in run_test.R
# ==============================================================================
# If you just want to use the functions in BaseSpaceDownloader via source(...)
# exit after having sourced.
if(interactive()){
    cat('BaseSpaceDownloader: Functions loaded\n')
    options(show.error.messages=FALSE)
    on.exit(options(show.error.messages=TRUE))
    stop()
}
# ==============================================================================

done<- suppressWarnings(suppressMessages(require(argparse)))
if(done == FALSE){
    cat('\nPlease install the "argparse" package. Open an R session and execute:\n\n')
    cat('> install.packages("argparse")\n\n')
    cat('Once you are at it, install also the data.table package, if not already installed:\n\n')
    cat('> install.packages("data.table")\n\n')
    quit(save= 'no', status= 1)
}

docstring<- sprintf("DESCRIPTION \\n\\
Download fastq files from BaseSpace given a project ID. \\n\\
\\n\\
EXAMPLE \\n\\
BaseSpaceDownloader.R -p 18434424 \\n\\
BaseSpaceDownloader.R -p 18434424 -r \"Ldono.*\\.gz\" \\n\\
\\n\\
Version %s", VERSION)

parser<- ArgumentParser(description= docstring, formatter_class= 'argparse.RawTextHelpFormatter')

parser$add_argument("-p", "--projid", help= "Project ID. Typically obtained from project's URL", required= TRUE)
parser$add_argument("-t", "--token", help= "Access token")
parser$add_argument("-o", "--outdir", help= "Output dir for fetched files.\\nBaseSpaceR will put here the dir Data/Intensities/BaseCalls/", default= '.')
parser$add_argument("-r", "--regex", help= "Regex to filter by file name. Default all files ending in .gz", default= '.*\\.gz$')
parser$add_argument("-e", "--echo", help= "Only show which files would be downloaded", action= 'store_true')

xargs<- parser$parse_args()

# ==============================================================================

if(length(xargs$token) == 0){
    accessToken<- getBasespaceToken(app_name= APP_NAME)
} else {
    accessToken<- xargs$token
}

files<- getFastqFromBaseSpace(
    proj_id= xargs$projid,
    accessToken= accessToken,
    dest_dir= xargs$outdir ,
    regex= xargs$regex,
    echo= xargs$echo,
    verbose= TRUE
)
cat(sprintf('\n%s files found with regex "%s"\n\n', length(files), xargs$regex))

quit(save= 'no')

Discrete = function(tree, data, mode = "ML", dependent = FALSE, res = NULL, resall = NULL, mrca = NULL, fo = NULL, mlt = 10, it = 100000, bi = 5000, sa = 100, pr = NULL, pa = NULL, hp = NULL, hpall = NULL, rj = NULL, rjhp = NULL, cv=FALSE, silent=TRUE, rm=T, reuse.tree=T) {

# CHECK FOR PROBLEMS IN THE DATA

if (class(tree) == 'phylo') {tree$node.label <- NULL}

if (class(tree) == "phylo") {treelabs = tree$tip.label} else if (class(tree) == "multiPhylo") {treelabs = attributes(tree)$TipLabel} else {
	stop("Tree must be of class phylo or multiPhylo")
}
if (!(class(data[,1]) %in% c("character", "factor"))) {stop("First column of data should contain species names.")}
if (length(setdiff(treelabs, data[,1]))>0) {stop(paste("No match found in the data:", paste(setdiff(tree$tip.label, data[,1]), collapse=", ")))}
if (length(setdiff(data[,1], treelabs))>0) {stop(paste("No match found in the phylogeny:", paste(setdiff(data[,1], tree$tip.label), collapse=", ")))}
if (length(setdiff(treelabs, data[,1]))>0 | length(setdiff(data[,1], treelabs))>0) {stop("Species in your phylogeny and data must match up exactly.")}
if (ncol(data) > 3) {stop("Too many columns in data: BayesTraits can only analyze one or two discrete traits.")}
if (!exists(".BayesTraitsPath") | !file.exists(.BayesTraitsPath)) {stop("Must define '.BayesTraitsPath' to be the path to BayesTraitsV2 on your computer. For example: .BayesTraitsPath <- User/Desktop/BayesTraitsV2")}

# WRITE INPUT FILE
if (mode == "Bayesian") {mode = 2} else {mode = 1}
if (ncol(data) == 2) {model = 1} else (model = 3)
input = c(model, mode)
if (!is.null(res)) {for (i in 1:length(res)) {input = c(input, paste("Restrict", res[i]))}}
if (dependent == FALSE) {
	input = c(input, "res q12 q34")
	input = c(input, "res q21 q43")
	input = c(input, "res q13 q24")
	input = c(input, "res q31 q42")
}
if (!is.null(resall)) {input = c(input, paste("resall", resall))}
if (!is.null(mrca)) {for (i in 1:length(mrca)) {input = c(input, paste("mrca", paste("mrcaNode", i, sep=""), mrca[i]))}}
if (!is.null(fo)) {for (i in 1:length(fo)) {input = c(input, paste("Fossil", paste("fossilNode", i, sep=""), fo[i]))}}
if (mode == 1) {input = c(input, paste("mlt", as.numeric(mlt)))}
if (mode == 2) {
	input = c(input, paste("it", format(it, scientific=F)))
	input = c(input, paste("bi", format(bi, scientific=F)))
	input = c(input, paste("sa", format(sa, scientific=F)))
	if (!is.null(pr)) {for (i in 1:length(pr)) {input = c(input, paste("prior", pr[i]))}}
	if (!is.null(pa)) {input = c(input, paste("pa", pa))}
	if (!is.null(rj)) {input = c(input, paste("rj", rj))}
	if (!is.null(hp)) {for (i in 1:length(hp)) {input = c(input, paste("hp", hp[i]))}}
	if (!is.null(hpall)) {input = c(input, paste("Hpall", hpall))}
	if (!is.null(rjhp)) {input = c(input, paste("rjhp", rjhp))}
	if (cv) {input = c(input, paste("cv"))}
}
input = c(input, paste("lf ./BTout.log.txt"))	
input = c(input, 'Schedule')
input = c(input, "run")
write(input, file="./inputfile.txt") 
if(!reuse.tree | !file.exists("./BT.current.tree.nex")) {
ape::write.nexus(tree, file="./BT.current.tree.nex", translate=T)	
}
write.table(data, file="./BT.current.data.txt", quote=F, col.names=F, row.names=F)
	
# RUN ANALYSIS
system(paste(.BayesTraitsPath, "./BT.current.tree.nex", "./BT.current.data.txt", "< ./inputfile.txt"), ignore.stdout = silent)

# GET OUTPUT
Skip = grep("Tree No", scan(file = "./BTout.log.txt", what="c", quiet=T, sep="\n", blank.lines.skip=FALSE)) - 1
Results = read.table("./BTout.log.txt", skip = Skip, sep = "\t",  quote="\"", header = TRUE)
Results = Results[,-ncol(Results)]

if (mode == 2) {
Skip.Schedule <- grep("Accepted", scan(file ="./BTout.log.txt.Schedule.txt", what="c", quiet=T, sep="\n", blank.lines.skip=FALSE)) - 1
Schedule = read.table("./BTout.log.txt.Schedule.txt",  skip=Skip.Schedule, sep = "\t",  quote="\"", header = TRUE)

if (mean(Schedule$X..Accepted<.2)>.5 & mean(Schedule$X..Accepted>.4)>.5) {
	prop.below <- 100*round(mean(Schedule$X..Accepted<.2),2)
	prop.above <- 100*round(mean(Schedule$X..Accepted>.4),2)
	warning(paste0("The acceptance rate was below .20 in ", prop.below, "% and above .40 in ",
		 	prop.above, "% of the iterations!"), call. = F)
}
} 

# DELETE FILES FROM DISK
if(rm) {
system(paste("rm ./BTout.log.txt"))
system(paste("rm ./inputfile.txt"))
if(!reuse.tree) {system(paste("rm", "./BT.current.tree.nex"))}
system(paste("rm", "./BT.current.data.txt"))
if (mode == 2) {
	system(paste("rm", "./BTout.log.txt.Schedule.txt"))
	}
}
# RETURN RESULTS

return(Results)
}





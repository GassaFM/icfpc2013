dmd=bash dmdnoobj.sh
opts=-g

current: myproblems.exe status.exe guess_inter.exe guess_bonus.exe

all: myproblems.exe train.exe train3.exe train3_guess.exe status.exe \
     real3_guess.exe op1_guess.exe op12_guess.exe op12if_guess.exe \
     train_guess.exe guess_sets.exe guess_fold.exe guess_inter.exe \
     guess_bonus.exe curl.lib libcurl.dll

clean:
	rm *.exe
	
curl.lib:
	winrar x curl.rar curl.lib

libcurl.dll:
	winrar x curl.rar libcurl.dll

myproblems.exe: myproblems.d icfputil/icfplib.d icfputil/lbv.d icfputil/common.d icfputil/probstat.d
	$(dmd) myproblems.d icfputil/icfplib.d icfputil/lbv.d icfputil/common.d icfputil/probstat.d $(opts)

train.exe: train.d icfputil/icfplib.d icfputil/lbv.d icfputil/common.d
	$(dmd) train.d icfputil/icfplib.d icfputil/lbv.d icfputil/common.d $(opts)

train3.exe: train3.d icfputil/icfplib.d icfputil/lbv.d icfputil/common.d
	$(dmd) train3.d icfputil/icfplib.d icfputil/lbv.d icfputil/common.d $(opts)
	
train3_guess.exe: train3_guess.d icfputil/icfplib.d icfputil/lbv.d icfputil/common.d
	$(dmd) train3_guess.d icfputil/icfplib.d icfputil/lbv.d icfputil/common.d $(opts)

real3_guess.exe: real3_guess.d icfputil/icfplib.d icfputil/lbv.d icfputil/common.d
	$(dmd) real3_guess.d icfputil/icfplib.d icfputil/lbv.d icfputil/common.d $(opts)

op1_guess.exe: op1_guess.d icfputil/icfplib.d icfputil/lbv.d icfputil/common.d icfputil/probstat.d icfputil/search.d
	$(dmd) op1_guess.d icfputil/icfplib.d icfputil/lbv.d icfputil/common.d icfputil/probstat.d icfputil/search.d $(opts)

op12_guess.exe: op12_guess.d icfputil/icfplib.d icfputil/lbv.d icfputil/common.d icfputil/probstat.d icfputil/search.d
	$(dmd) op12_guess.d icfputil/icfplib.d icfputil/lbv.d icfputil/common.d icfputil/probstat.d icfputil/search.d $(opts)

op12if_guess.exe: op12if_guess.d icfputil/icfplib.d icfputil/lbv.d icfputil/common.d icfputil/probstat.d icfputil/search.d icfputil/request.d
	$(dmd) op12if_guess.d icfputil/icfplib.d icfputil/lbv.d icfputil/common.d icfputil/probstat.d icfputil/search.d icfputil/request.d $(opts)

guess_sets.exe: guess_sets.d icfputil/icfplib.d icfputil/lbv.d icfputil/common.d icfputil/probstat.d icfputil/search_sets.d icfputil/request.d
	$(dmd) guess_sets.d icfputil/icfplib.d icfputil/lbv.d icfputil/common.d icfputil/probstat.d icfputil/search_sets.d icfputil/request.d $(opts)

guess_fold.exe: guess_fold.d icfputil/icfplib.d icfputil/lbv.d icfputil/common.d icfputil/probstat.d icfputil/search_sets.d icfputil/request.d
	$(dmd) guess_fold.d icfputil/icfplib.d icfputil/lbv.d icfputil/common.d icfputil/probstat.d icfputil/search_sets.d icfputil/request.d $(opts)

guess_inter.exe: guess_inter.d icfputil/icfplib.d icfputil/lbv.d icfputil/common.d icfputil/probstat.d icfputil/search_sets.d icfputil/request.d
	$(dmd) guess_inter.d icfputil/icfplib.d icfputil/lbv.d icfputil/common.d icfputil/probstat.d icfputil/search_sets.d icfputil/request.d $(opts)

guess_bonus.exe: guess_bonus.d icfputil/icfplib.d icfputil/lbv.d icfputil/common.d icfputil/probstat.d icfputil/search_bonus.d icfputil/request.d
	$(dmd) guess_bonus.d icfputil/icfplib.d icfputil/lbv.d icfputil/common.d icfputil/probstat.d icfputil/search_bonus.d icfputil/request.d $(opts)

train_guess.exe: train_guess.d icfputil/icfplib.d icfputil/lbv.d icfputil/common.d icfputil/probstat.d
	$(dmd) train_guess.d icfputil/icfplib.d icfputil/lbv.d icfputil/common.d icfputil/probstat.d $(opts)

status.exe: status.d
	$(dmd) status.d $(opts)
		
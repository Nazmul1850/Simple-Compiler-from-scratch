yacc -y -d 1705115.y
g++ -w -c -o y.o y.tab.c
flex 1705115.l
g++ -w -c -o l.o lex.yy.c
g++ y.o l.o -lfl 
./a.out input.c # replace wiht input file name
sudo g++ optimizer.cpp 
./a.out

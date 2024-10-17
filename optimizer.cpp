#include <bits/stdc++.h>
using namespace std;

void split(string s, vector<string> &codes){
    /// split for space character
    stringstream ss(s);
    string word;
    while(ss >> word){
         codes.push_back(word);
    }
}

string to_lower(string s){
    string s1 = "";
    for(char c : s){
        if(c >= 'A' && c <= 'Z') s1 += c +'a'-'A';
        else s1 +=c;
    }
    return s1;
}

void optimize(ifstream &file){
    ofstream opt_file("optimized_code.asm");
    string line;
    while(getline(file,line)){
        vector<string> codes;
        int i = 1;
        split(line,codes);
        while(codes.size() != 0 && to_lower(codes[0]) == "push"){
            string line2;
            i = 0;
            getline(file,line2);
            vector<string> codes2;
            split(line2,codes2);
            if(codes2.size()!= 0 && to_lower(codes2[0]) == "pop"){
                if(codes[1] != codes2[1]){
                    opt_file << "MOV "+codes2[1]<<", "<<codes[1]<<endl;
                }
                break;
            }
            else if(codes2.size()!= 0 && to_lower(codes2[0]) == "push"){
                opt_file << line << endl;
                codes.clear();
                codes.push_back(codes2[0]); codes.push_back(codes2[1]);
                line = line2;
            }
            else{
                opt_file << line << endl;
                opt_file << line2 << endl;
                break;
            }
        }
        if(i) opt_file << line << endl;
    }
    opt_file.close();

}

int main(){
    ifstream file("code.asm");
    optimize(file);
    file.close();

}

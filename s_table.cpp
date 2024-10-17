#include<bits/stdc++.h>
using namespace std;

class SymbolInfo{
    string name="", type="";
    string id_type="",state="";
    int id;
    int size,index;
public:
	vector<SymbolInfo*> params,args;
    string varName = "",asmCode = "";
    vector<pair<string,string>> inc_ops;
    int isEmpty;
    	SymbolInfo(string name, string type){
        //cout<<"kajer"<<endl;
        this->name = name;
        this->type = type;
        id = -1;
        size = 0;
        index = -1;
    }
    SymbolInfo(SymbolInfo *sym){
    	name = sym->name;
    	type = sym->type;
    	id_type = sym->id_type;
    	id = sym->id;
    	size = sym->size;
    	type = sym->type;
    	state = sym->state;
        varName = sym->varName;
    	for(int i = 0; i < sym->params.size(); i++){
    		params.push_back(sym->params[i]);
    	}
    }
    string setName(string s) {name = s;}
    string getName(){ return name; }
    string setType(string s) {type = s;}
    string getType() { return type; }
    void setSize(int s) {size = s;}
    int getSize() {return size;}
    void setId(int id) {this->id = id; }
    int getId() { return id; }
    void setID_type(string s) {id_type = s;}
    string getID_type() {return id_type;}
    void setIndex(int i) {index = i;}
    int getIndex() {return index;}
    void setState(string s) {state = s;}
    string getState() {return state;}
};

class ScopeTable{
    vector<vector<SymbolInfo>> hash_table;
    int len,no_of_child;
    string id;
    ScopeTable *parent;
    ///linking with parent
public:
    ScopeTable(int len, ScopeTable *st){
        this->len = len;
        hash_table.resize(len);
        no_of_child = 0;
        id = "1";
        parent = NULL;
        setParent(st);
    }
    ~ScopeTable(){
        hash_table.resize(0);
        parent = NULL;
        delete parent;
    }

    void setParent(ScopeTable *st){
        if(st == NULL) return;
        parent = st;
        parent->incChild();
        id = parent->id + "." +to_string(parent->getNoOfChild());
    }

    ScopeTable *getParent() { return parent; }

    void incChild() { no_of_child++; }
    int getNoOfChild() { return no_of_child; }

    int hashFunc(string name){
        int s = 0;
        for(char c : name) s += c;
        return (s%len);
    }
    bool Insert(SymbolInfo sym){
        if(lookUp(sym.getName()) == NULL){
            int idx = hashFunc(sym.getName());
            sym.setId(hash_table[idx].size());
            hash_table[idx].push_back(sym);
            return true;
        }
        return false;
    }
    SymbolInfo *lookUp(string name){
        int idx = hashFunc(name);
        for(int i = 0; i < hash_table[idx].size(); i++){
            SymbolInfo *s = &hash_table[idx][i];
            if(name == s->getName()){
                return s;
            }
        }
        return NULL;
    }

    bool Delete(string name){
        SymbolInfo *st = lookUp(name);
        if(st == NULL) return false;
        int id = st->getId();

        int idx = hashFunc(name);
//        while(id < hash_table[idx].size() - 1){
//            hash_table[idx][id] = hash_table[idx][id+1];
//            id++;
//        }
        hash_table[idx].erase(hash_table[idx].begin() + id);

        //hash_table[idx].resize(id); ///for this line symbolInfo need a constructor without parameters
        return true;
    }

    void print(ofstream &logfile){
        logfile << "Scope Table # ";
        logfile<<id<<endl;

        for(int i = 0; i < len; i++){
            if(hash_table[i].size() == 0) continue;
            logfile << i << "----> ";
            for(int j = 0; j < hash_table[i].size(); j++){
                SymbolInfo sym = hash_table[i][j];
                logfile<< " < " << sym.getName() << " : " << sym.getType() <<">";
            }
            logfile << endl;
        }
        logfile << endl;
    }
    string getId(){ return id;}
};

class SymbolTable{
    ScopeTable *curr;
    int total_bucket;
public:
    SymbolTable(int n){
        total_bucket = n;
        curr = new ScopeTable(total_bucket,NULL);
    }
    ~SymbolTable(){
        delete curr;
    }
    void enterScope(){
        ScopeTable *st = new ScopeTable(total_bucket,curr);
        curr = st;
    }
    void exitScope(ofstream &logfile){
    	
    	printAllScope(logfile);
        if(curr == NULL){
            return;
        }
        ScopeTable *temp = curr;
        curr = temp->getParent();
        delete temp;
    }
    bool Insert(string name, string type){
        if(curr == NULL){
            return false;
        }
        SymbolInfo st(name,type);
        if(curr->Insert(st)){
            return true;
        }
        //cout << name <<" already exists in current ScopeTable"<<endl;
        return false;
    }
    bool Insert(SymbolInfo *sym){
        if(curr == NULL){
            return false;
        }
        SymbolInfo st(sym);
        if(curr->Insert(st)){
            return true;
        }
        //cout << st.getName() <<" already exists in current ScopeTable"<<endl;
        return false;
    }
    bool Remove(string name){
        if(curr == NULL){
            return false;
        }
        return curr->Delete(name);
    }
    SymbolInfo *lookUp(string name){
        SymbolInfo *st;
        ScopeTable *temp = curr;
        while(temp != NULL){
            st = temp->lookUp(name);
            if(st != NULL) return st;
            temp = temp->getParent();
        }
        return NULL;
    }
    
    SymbolInfo *lookUpCurr(string name){
        if(curr == NULL){
            return NULL;
        }
        return curr->lookUp(name);
    }

    void printCurrScope(ofstream &logfile){
        if(curr == NULL){
            return;
        }
        curr->print(logfile);
    }

    void printAllScope(ofstream &logfile){
        if(curr == NULL){
            return;
        }
        ScopeTable *temp = curr;
        while(temp != NULL){
            temp->print(logfile);
            temp = temp->getParent();
        }
    }
    string curr_id(){return curr->getId();}

};


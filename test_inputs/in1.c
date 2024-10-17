int main(){
    int a,b,c[3],d,e,f;
    a = 2;
    b = 20;
    println(a);
    println(b);
    c[0] = 10;
    c[1] = c[0] - 2;
    c[2] = c[0] + 2;
    d = c[0];
    println(d);
    d = c[1];
    println(d);
    d = c[2];
    println(d);
    d = a && b;
    println(d);
    if((c[0] < c[2]) && !(c[1] < 0)){
        d = a*b - 10;
        e=69;
        println(e);
    }
    else{
        d = a*b + 10;
        f = 109;
        println(f);
    }
    println(d);
}

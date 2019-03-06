public class Utilities {
 
    public static Decimal add(Decimal a, Decimal b) {
        if (a != null && b != null) return a + b;
        else if (a != null) return a;
        else if (b != null) return b;
        else return null;
    }   

}

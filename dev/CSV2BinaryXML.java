import java.io.File;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.LineNumberReader;

public class CSV2BinaryXML {

    public static final void main(String[] args) {
        try {
            LineNumberReader lis = new LineNumberReader(new FileReader(new File(
                    "slovak_vocabulary.csv")));
            String line = null;
            FileOutputStream fos = new FileOutputStream(new File("slovak_vocabulary.xml"));
            fos.write("<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n".getBytes());
            fos.write("<wordlist>\n".getBytes());
            while ((line = lis.readLine()) != null) {
                String[] pair = line.split(",");
                String w = pair[0];
                w = w.trim();
                if (w.length() == 1) {
                    continue;
                }
                int f = 1;
                if (pair.length > 1) {
                    f = Integer.valueOf(pair[1]);
                }
                fos.write(("<w f=\"" + f + "\">" + w.trim() + "</w>\n").getBytes());
            }
            fos.write("</wordlist>\n".getBytes());
        } catch (Exception ex) {
            ex.printStackTrace();
        }
    }
}

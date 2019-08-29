/* SerializeData.java
 *
 * This command-line java applet facilitates constructing the necessary files for
 *  the Signature Commons Data API from UUID-transformed either a GMT or a Rank Matrix.
 */

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;

public class SerializeData {

	public static final String ANSI_RESET = "\u001B[0m";
	public static final String ANSI_BLACK = "\u001B[30m";
	public static final String ANSI_RED = "\u001B[31m";
	public static final String ANSI_GREEN = "\u001B[32m";
	public static final String ANSI_YELLOW = "\u001B[33m";
	public static final String ANSI_BLUE = "\u001B[34m";
	public static final String ANSI_PURPLE = "\u001B[35m";
	public static final String ANSI_CYAN = "\u001B[36m";
	public static final String ANSI_WHITE = "\u001B[37m";
	
	public static void main(String[] args) {
		String input = "";
		String outputSO = "";
		String mode = "";
		boolean transpose = false;
		boolean rank = false;
		boolean printResult = false;
		
		if(args.length == 0 ) {
			printhelp();
		}
		else {
			try {
				for(int i=0; i<args.length; i++) {
					if(args[i].equals("-h") || args[i].equals("--help")) {
						printhelp();
						break;
					}
					else if(args[i].equals("-i") || args[i].equals("--input")) {
						i++;
						input = args[i];
						outputSO = input.split("\\.")[0]+".so";
					}
					else if(args[i].equals("-o") || args[i].equals("--output")) {
						i++;
						outputSO = args[i];
					}
					else if(args[i].equals("-m") || args[i].equals("--mode")) {
						i++;
						mode = args[i];
					}
					else if(args[i].equals("-t") || args[i].equals("--transpose")) {
						transpose = true;
					}
					else if(args[i].equals("-r") || args[i].equals("--rank")) {
						rank = true;
					}
					else if(args[i].equals("-v") || args[i].equals("--verbose")) {
						printResult = true;
					}
				}
			}
			catch(Exception e) {
				printhelp();
				e.printStackTrace();
				System.exit(0);
			}
		}

		if(mode.equals("")) {
			
		}
		else if(!input.equals("") && !outputSO.equals("")) {
			try {
				if(mode.equals("gmt")) {
					serializeGMTFile(input, outputSO);
				}
				else if(mode.equals("expression")){
					serializeMatrix(input, transpose, outputSO, rank, printResult);
				}
				else {
					printErrorStatus("Please specify a mode -m | --mode (gmt or expression).");
				}
				
			}
			catch(Exception e) {
				printErrorStatus("Something went wrong. It wasn't my fault.");
				e.printStackTrace();
			}
		}
		
	}
	
	private static void printhelp() {
		System.out.println("Create SO objects from GMT files and gene expression matrices.");
		System.out.println("-h | --help \t print help");
		System.out.println("-m | --mode \t either 'gmt' or 'expression'");
		System.out.println("-i | --input \t input GMT file (weights are discarded) when -m (--mode) is 'gmt' and expression matrix for -m is 'expression'");
		System.out.println("-o | --output \t output SO file (default: same as -g name .so)");
		System.out.println("-t | --transpose \t transpose input file with entities as columns and signatures as rows");
		System.out.println("-r | --rank \t rank genes in signature. Results in a short representation.");
		System.out.println("-v | --verbose \t print result in std");
		System.out.println("Example: java -jar serializegmt.jar -m expression -i testrank.tsv -o testout.so -r -v");
	}
	
	private static HashMap<String, Object> readMatrixTransposed(String _datamatrix) {

		float[][] matrix = new float[0][0];
		ArrayList<String> entities = new ArrayList<String>();
		ArrayList<String> signature = new ArrayList<String>();
		
		try{
			BufferedReader br = new BufferedReader(new FileReader(new File(_datamatrix)));
			String line = br.readLine(); // read header
			String[] sp = line.split("\t");
			
			for(int i=1; i<sp.length; i++) {
				entities.add(sp[i]);
			}
			
			int numRows = sp.length-1;
			int numCols = 0;
			
			while((line = br.readLine())!= null){
				if(line.length() > 0) {
					numCols++;
				}
			}
			br.close();
			
			matrix = new float[numRows][numCols];
			
			br = new BufferedReader(new FileReader(new File(_datamatrix)));
			line = br.readLine(); // read header
			int idx = 0;
			
			while((line = br.readLine())!= null){
				sp = line.split("\t");
				
				signature.add(sp[0]);
				for(int i=1; i<sp.length; i++) {
					matrix[i-1][idx] = Float.parseFloat(sp[i]);
				}
				idx++;
			}
			br.close();
			
			printGoodStatus("Detected "+numRows+" unique genes");
			printGoodStatus("Detected "+numCols+" unique signatures");
		}
		catch(Exception e){
			printErrorStatus("Error when reading file. Input file possibly does not exist or has wrong format.");
			e.printStackTrace();
			System.exit(0);
		}
		
		HashMap<String, Object> matrix_so = new HashMap<String, Object>();
		matrix_so.put("entity_id", entities.toArray(new String[0]));
		matrix_so.put("signature_id", signature.toArray(new String[0]));
		matrix_so.put("matrix", matrix);
		
		return matrix_so;
	}
	
	private static HashMap<String, Object> readMatrix(String _datamatrix) {
		float[][] matrix = new float[0][0];
		ArrayList<String> entities = new ArrayList<String>();
		ArrayList<String> signature = new ArrayList<String>();
		
		try{
			BufferedReader br = new BufferedReader(new FileReader(new File(_datamatrix)));
			String line = br.readLine(); // read header
			String[] sp = line.split("\t");
			
			for(int i=1; i<sp.length; i++) {
				signature.add(sp[i]);
			}
			
			int numCols = sp.length-1;
			int numRows = 0;
			
			while((line = br.readLine())!= null){
				if(line.length() > 0) {
					numRows++;
				}
			}
			br.close();
			
			matrix = new float[numRows][numCols];
			
			br = new BufferedReader(new FileReader(new File(_datamatrix)));
			line = br.readLine(); // read header
			int idx = 0;
			
			while((line = br.readLine())!= null){
				sp = line.split("\t");
				
				entities.add(sp[0]);
				for(int i=1; i<sp.length; i++) {
					matrix[idx][i-1] = Float.parseFloat(sp[i]);
				}
				idx++;
			}
			br.close();
			
			printGoodStatus("Detected "+numRows+" unique genes");
			printGoodStatus("Detected "+numCols+" unique signatures");
		}
		catch(Exception e){
			printErrorStatus("Error when reading file. Input file possibly does not exist or has wrong format.");
			e.printStackTrace();
			System.exit(0);
		}
		
		HashMap<String, Object> matrix_so = new HashMap<String, Object>();
		matrix_so.put("entity_id", entities.toArray(new String[0]));
		matrix_so.put("signature_id", signature.toArray(new String[0]));
		matrix_so.put("matrix", matrix);
		
		return matrix_so;
	}
	
	public static void serializeMatrix(String _datamatrix, boolean _transpose, String _output, boolean _rank, boolean _printResult) {
		HashMap<String, Object> matrix_so = null;
		if(_transpose) {
			matrix_so = readMatrixTransposed(_datamatrix);
		}
		else {
			matrix_so = readMatrix(_datamatrix);
		}
		
		if(_rank) {
			float[][] matrix = (float[][]) matrix_so.get("matrix");
			short[][] rankMatrix = new short[matrix.length][matrix[0].length];
			float[] temp = new float[matrix.length];
			
			for(int i=0; i<matrix[0].length; i++) {
				for(int j=0; j<matrix.length; j++) {
					temp[j] = matrix[j][i];
				}
				short[] ranks = ranksHash(temp);
				for(int j=0; j<ranks.length; j++) {
					rankMatrix[j][i] = ranks[j];
				}
			}
			
			matrix_so.put("matrix", rankMatrix);
			
			if(_printResult) {
				String[] sigs = (String[]) matrix_so.get("signature_id");
				System.out.println("\t"+String.join(", ",sigs));
				for(int i=0; i<rankMatrix.length; i++) {
					System.out.println(((String[]) matrix_so.get("entity_id"))[i]+"\t"+Arrays.toString(rankMatrix[i]));
				}
			}
		}
		
		serialize(matrix_so, _output);
		
		printGoodStatus("Serialization completed into file "+_output);
		printGoodStatus("Done");
	}
	
	public static void serializeGMTFile(String _gmtfile, String _output) {
		
		HashMap<String, short[]> genesets = new HashMap<String, short[]>();
		HashMap<String, Short> dictionary = new HashMap<String, Short>();
		HashMap<Short, String> revDictionary = new HashMap<Short, String>();
		
		try{
			
			BufferedReader br = new BufferedReader(new FileReader(new File(_gmtfile)));
			String line = "";
			
			// building index mapping first
			printGoodStatus("Building gene index");
			
			short idx = Short.MIN_VALUE;
			boolean commas = false;
			while((line = br.readLine())!= null){
				String[] sp = line.split("\t");
				
				for(int i=2; i<sp.length; i++) {
					String[] gene_split = sp[i].split(",");
					if(gene_split.length > 1) {
						commas = true;
					}
					String gene = gene_split[0];
					
					if(!dictionary.containsKey(gene)) {
						dictionary.put(gene, idx);
						revDictionary.put(idx, gene);
						idx++;
					}
				}
			}
			br.close();
			
			printGoodStatus("Detected "+dictionary.size()+" unique genes");
			if(commas) {
				printWarningStatus("Gene weights detected and removed");
			}
			else {
				printGoodStatus("Unweighted GMT detected");
			}
			
			br = new BufferedReader(new FileReader(new File(_gmtfile)));
			line = "";
			
			while((line = br.readLine())!= null){
				
				String[] sp = line.split("\t");
				String uid = sp[0];
				
				ArrayList<Short> arrl = new ArrayList<Short>();
				
				for(int i=2; i<sp.length; i++) {
					sp[i] = sp[i].split(",")[0];
					arrl.add(dictionary.get(sp[i]));
				}
				
				short[] set = new short[arrl.size()];
				for(int i=0; i<arrl.size(); i++) {
					set[i] = (short) arrl.get(i);
				}
				
				if(set.length < 1) {
					printWarningStatus("Warning: geneset "+uid+" is empty");
				}
				
				genesets.put(uid, set);
			}
			br.close();
			
		}
		catch(Exception e) {
			printErrorStatus("Error when reading file. Input file possibly does not exist or has wrong format.");
			e.printStackTrace();
			System.exit(0);
		}		
		
		HashMap<String, Object> setdata = new HashMap<String, Object>();
		setdata.put("geneset", genesets);
		setdata.put("dictionary", dictionary);
		setdata.put("revDictionary", revDictionary);
		
		printGoodStatus("Detected "+genesets.size()+" gene sets");
		printGoodStatus("Created compressed geneset representation");
		
		serialize(setdata, _output);
		printGoodStatus("Serialized data to file: "+_output);
		printGoodStatus("All done");
	}
	
	public static void printGoodStatus(String _text) {
		System.out.println(ANSI_GREEN + _text + ANSI_RESET);
	}
	
	public static void printWarningStatus(String _text) {
		System.out.println(ANSI_YELLOW + _text + ANSI_RESET);
	}
	
	public static void printErrorStatus(String _text) {
		System.out.println(ANSI_RED + _text + ANSI_RESET);
	}
	
	public static void serialize(Object _o, String _outfile) {
		try {
			FileOutputStream file = new FileOutputStream(_outfile);
	        ObjectOutputStream out = new ObjectOutputStream(file);
	         
	        // Method for serialization of object
	        out.writeObject(_o);
	         
	        out.close();
	        file.close();
		}
		catch(Exception e) {
			e.printStackTrace();
		}
	}
	
	private static Object deserialize(String _file) {
		Object ob = null;
		try{   
            // Reading the object from a file
            FileInputStream file = new FileInputStream(_file);
            ObjectInputStream in = new ObjectInputStream(file);
             
            // Method for deserialization of object
            ob = (Object)in.readObject();
             
            in.close();
            file.close();
        }
        catch(Exception e){
            e.printStackTrace();
        }
		
		return ob;
	}
	
	private static short[] ranksHash(float[] _temp) {
		
		float[] sc = new float[_temp.length];
		System.arraycopy(_temp, 0, sc, 0, _temp.length);
		Arrays.sort(sc);
		
		HashMap<Float, Short> hm = new HashMap<Float, Short>(sc.length);
		for (short i = 0; i < sc.length; i++) {
			hm.put(sc[i], i);
		}
		
		short[] ranks = new short[sc.length];
		
		for (int i = 0; i < _temp.length; i++) {
			ranks[i] = (short)(hm.get(_temp[i])+1);
		}
		return ranks;
	}
}



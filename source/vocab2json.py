import json 
import argparse
 
def main():
    parser = argparse.ArgumentParser(
        description='Infuse the top percentage of parallel sentences with semantic divergences')
    parser.add_argument('--vocab', help='source language')
    o = parser.parse_args()  

    # resultant dictionary 
    dict1 = {"<pad>": 0,"<unk>": 1,"<s>": 2,"</s>": 3}

    # fields in the sample file  

    with open(o.vocab,'r') as fh: 
        
        # count variable for employee id creation 
        l = 1
        for line in fh:   
            # reading line by line from the text file 
            piece = line.rstrip().split('\t')[0] 
            dict1[piece] = l
            l = l + 1
  
    # creating json file         
    out_file = open(o.vocab + '.4sockeye', "w", encoding="utf-8") 
    json.dump(dict1, out_file, indent=4, ensure_ascii=False) 
    out_file.close()
if __name__ == '__main__':
    main()

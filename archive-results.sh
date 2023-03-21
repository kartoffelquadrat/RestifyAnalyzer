#check if input provided
if [ "$#" -ne 1 ]; then
    echo "Illegal number of parameters"
    exit 255
fi

# check if provided arg is a dir
if [[ -d $1 ]]; then
    echo "OK, $1 is a directory"
elif [[ -f $1 ]]; then
    echo "ERROR, $1 is a file"
    exit 255
else
    echo "$1 is not valid"
    exit 255
fi

# remove trailing slashes
ZIP=${1//\/}.zip
echo $ZIP
zip -qr $ZIP $1


# Compute checksum
HASH=$(md5sum $ZIP | cut -f1 -d ' ')
echo $HASH

# Create directory using checksum value
ssh -t mschie3@mimi.cs.mcgill.ca "cd /home/2019/mschie3/public_html/restify/testreports; mkdir -p $HASH"

echo "Hash dir created on server. Ready for upload."

# Copy file to server into newly created directory
scp $ZIP mschie3@mimi.cs.mcgill.ca:/home/2019/mschie3/public_html/restify/testreports/$HASH

echo "Upload complete."
rm $ZIP

# Print public URL for uploaded file
echo "----------"
echo "https://www.cs.mcgill.ca/~mschie3/restify/testreports/$HASH/$ZIP"


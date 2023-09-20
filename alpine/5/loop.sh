for file in dist/react/* ; do 
filename=$(basename -- "$file") 
extension="${filename##*.}" 
filename="${filename%.*}" 
version=v$INVOICENINJA_VERSION 
echo "Copying $file to /var/www/app/public/react/$filename"."$version"."$extension"
cp $file /var/www/app/public/react/$filename"."$version"."$extension 
done 
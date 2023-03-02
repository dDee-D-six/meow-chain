read -p "Enter Github Token: " github_token 
if [ -z "$github_token" ]
then
    echo "Schema Code is empty"
    exit 1
fi
docker build . -t meow/node:latest
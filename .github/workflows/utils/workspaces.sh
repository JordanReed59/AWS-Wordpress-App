# Capture barnch name in variable from parameters
export BRANCH_NAME=$1

# Capture the output of terraform workspace list into an array
echo "terraform workspace list"
terraform workspace list
workspace_list=($(terraform workspace list))
echo $workspace_list

# Check if the search string exists in the workspace list
found=false

echo "Branch name: $BRANCH_NAME"
export WORKSPACE_NAME=$(python ../../.github/workflows/utils/branch_mapping.py "$BRANCH_NAME")

# find if workspace exists already
for item in "${workspace_list[@]}"; do
    if [[ "$item" == $WORKSPACE_NAME ]]; then
        found=true
        break
    fi
done

# switch to or create workspace
if [ "$found" = true ]; then
    echo "Switching to workspace '$WORKSPACE_NAME'."
    terraform workspace select $WORKSPACE_NAME
else
    echo "Creating and switching to workspace '$WORKSPACE_NAME'."
    terraform workspace new $WORKSPACE_NAME
fi
terraform workspace list

# terragrunt-infra-modules


How do you change a module?
Local changes
Here is how to test out changes to a module locally:

git clone this repo.
Update the code as necessary.
Go into the folder where you have the terragrunt.hcl file that uses a module from this repo (preferably for a dev or staging environment!).
Run terragrunt plan --terragrunt-source <LOCAL_PATH>, where LOCAL_PATH is the path to your local checkout of the module code.
If the plan looks good, run terragrunt apply --terragrunt-source <LOCAL_PATH>.
Using the --terragrunt-source parameter (or TERRAGRUNT_SOURCE environment variable) allows you to do rapid, iterative, make-a-change-and-rerun development.

Releasing a new version
When you're done testing the changes locally, here is how you release a new version:

Update the code as necessary.

Commit your changes to Git: git commit -m "commit message".

Add a new Git tag using one of the following options:

Using GitHub: Go to the releases page and click "Draft a new release".
Using Git:
git tag -a v0.0.2 -m "tag message"
git push --follow-tags
Now you can use the new Git tag (e.g. v0.0.2) in the ref attribute of the source URL in terragrunt.hcl.

Run terragrunt plan.

If the plan looks good, run terragrunt apply.

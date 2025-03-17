# Uprgrading instructions

## Finding correct versions of `nginx` and `openjdk-21-jdk`

```bash
# find latest version of nginx
docker run --rm ubuntu:22.04 bash -c "apt-get update && apt-cache policy nginx | grep Candidate | awk '{print \$2}'"

# find latest version of openjdk
docker run --rm ubuntu:22.04 bash -c "apt-get update && apt-cache policy openjdk-21-jdk | grep Candidate | awk '{print \$2}'"
```

## Updating the code to mirror these versions

```bash
# on master branch
git switch master;
# replace values in Notes.md
git commit --amend --no-edit;

# on solutions branch
git sw solutions;
# this should be a painless rebase
git rebase master;
```

**Note that there are several commits** that reference these values:

```bash
# find all commits that reference the current version of nginx
git rebase --exec 'if git grep -q "<<CURRENT_VERSION_OF_NGINX_BEING_USED>>"; then echo "String found, stopping rebase."; exit 1; fi' -i master
# this will break on any commits with those values
## be sure catch any conflicted files first
git status;
## if none, look for that string
git --no-pager grep "<<CURRENT_VERSION_OF_NGINX_BEING_USED>>"
## edit all files
git add . && git ci --amend --no-edit && git rebase --continue

# REBASE WITH CARE—particularly the var files for each ENV
```

**Be sure to compare commits with `origin/solution` prior to force pushing

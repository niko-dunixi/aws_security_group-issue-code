## Code to replicate issue

https://github.com/terraform-providers/terraform-provider-aws/issues/14898

## Expected Behavior
I set my security groups to names that were long but deterministic. The uniqueness is used to prevent collisions within a shared organization AWS account, yet deterministic so as to be easy to look up and reference later.

## Actual Behavior
When the name is set to a long contiguous set of alphanumeric characters, the threshold appears to be <= 26 in length, the name is not set and instead the name_prefix is used. The deploy will succeed. Subsequent deployments will destroy/create the resource because the script has not changed, but the resource deployed and saved within the tfstate does not match the one in code.

With security groups that are in use, this will fail the deployment because two cannot share the same name and terraform will try to create the replacement security group first that will replace the old one, thus causing a duplicate security group error from the AWS API.

One can work-around this, albeit in a less than ideal manor, by splitting and re-joining the string with a separator character; however it is not ideal since the name should just be used if a valid name has been provided.

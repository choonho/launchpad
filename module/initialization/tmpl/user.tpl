enabled: true
image:
    name: spaceone/spacectl
    version: 1.9.1
skip_health_check: false
domain: user
main:
  import:
    - /root/spacectl/apply/local_domain.yaml
    - /root/spacectl/apply/statistics.yaml

  var:
    domain_name: spaceone
    default_language: ko
    default_timezone: Asia/Seoul
    domain_owner: ${domain_owner}
    domain_owner_password: ${domain_owner_password}
    project_admin_policy_type: MANAGED
    project_admin_policy_id: policy-managed-project-admin
    project_viewer_policy_type: MANAGED
    project_viewer_policy_id: policy-managed-project-viewer
    domain_admin_policy_type: MANAGED
    domain_admin_policy_id: policy-managed-domain-admin
    domain_viewer_policy_type: MANAGED
    domain_viewer_policy_id: policy-managed-domain-viewer

  tasks: []

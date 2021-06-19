# Help text

HELP="${BOLD-}$(echo "${PROJECT_TITLE}" | tr '[:lower:]' '[:upper:]')${RESET-}

${BOLD-}USAGE${RESET-}

    carnet [OPTIONS] [CARGO COMMANDS & OPTIONS]
    carnet [OPTIONS] [CARNET COMMAND]

${BOLD-}GENERAL OPTIONS${RESET-}

    --carnet:config-dir=...         Override default configuration 
                                    directory.
    --carnet:end                    Stop processing Carnet flags and 
                                    commands.
    --carnet:verbose                Show debugging messages.
    --carnet:version                Show version information and exit.
    --carnet:legal                  Show legal information and exit.
    --carnet:help                   Show this help message and exit.
    
${BOLD-}SANDBOX OPTIONS${RESET-}

    --carnet:disable-sandbox        Bypass sandboxing completely.
    --carnet:unsandbox-filesystem   Allow normal filesystem access.
    --carnet:unsandbox-processes    Allow normal access to processes
                                    and IPC.
    --carnet:unsandbox-network      Allow normal network access.
    --carnet:unsandbox-session      Do not sandbox session.
    --carnet:unsandbox-cargo-home   Allow read-write access to 
                                    cargo's home directory.
    --carnet:ro-paths=...           Allow read-only access to colon-
                                    separated list of paths.
    --carnet:rw-paths=...           Allow read-write access to colon-
                                    separated list of paths.
    
${BOLD-}AUTHENTICATION OPTIONS${RESET-}

    --carnet:disable-verification   Disable automatic verification.
                                    See carnet:edit and carnet:done.  
  
${BOLD-}COMMANDS${RESET-}

    carnet:help          Show this help message and exit.
    carnet:sandbox-run   Run arbitrary commands in sandbox.
    carnet:seal          Seal current crate.
    carnet:verify        Verify current crate.
    carnet:files         View all files that get sealed.
    carnet:own           Set origin of current as local.
    carnet:disown        Set origin of current crate as foreign.
    carnet:distrust      Unregister the current crate from cache.
    carnet:init          Initialize existing cargo crate. 
    carnet:uninit        Uninitialize and unregister current crate.
                         
    ${BOLD-}CONFIGURATION SETTINGS${RESET-}
    
    carnet:enable        Set a persistent configuration setting.
    carnet:disable       Unset a persistent configuration setting.
    
    ${BOLD-}SESSION MANAGEMENT${RESET-}
    
    carnet:edit          Temporarily suspend automatic verification.
    carnet:done          Resume automatic verification.


    ${BOLD-}IMPORTANT NOTE${RESET-}: Carnet is pre-alpha software. Sandboxing works. 
    Crate authentication is not ready yet. Identity and key life-
    cycle management are WIH.
    

${BOLD-}INTRODUCTION${RESET-}

$(printf "${DESCRIPTION}" | tr -d '\n' | sed -E 's/ +/ /g' | fold -sw 66 | sed -E 's/^/    /g')
                     
    Carnet imposes two types of security constraints on Cargo:
    
        1. It can isolate Cargo to a separate system-enforced 
           sandbox, only allowing access to a limited subset of 
           system resources.
       
        2. It can authenticate crates before allowing Cargo to 
           operate on them. (This feature is incomplete and should 
           not be used yet.)
    
    Carnet can be used in place of Cargo, transparently accepting all
    its arguments:
    
        ${DIM-}carnet test${RESET-}
        ${DIM-}carnet build --release${RESET-}
    
    In both the commands above, Carnet will first verify the 
    authenticity of the crate and then run the corresponding cargo 
    command in a restrictive sandbox (unless configured otherwise). 
    This sandbox prevents Cargo from accessing the network, most of 
    the user's home directory, most of the filesystem, and so on by
    default.
    
    Sandbox restrictions can be relaxed easily or even disabled
    entirely by passing the appropriate flag to Carnet:
    
        ${DIM-}carnet --unsandbox-network     ...${RESET-}
        ${DIM-}carnet --unsandbox-cargo-home  ...${RESET-}
        ${DIM-}carnet --unsandbox-processes   ...${RESET-}
        ${DIM-}carnet --unsandbox-session     ...${RESET-}
        ${DIM-}carnet --unsandbox-filesystem  ...${RESET-}
        ${DIM-}... and so on.${RESET-}
    
    In addition to general flags that act on entire resource classes,
    Carnet can also expose individual files and directories within 
    the sandbox via the flags '--carnet:ro-paths' and 
    '--carnet:rw-paths'.
    
    To avoid ambiguity, flags intended for Carnet can be prefixed 
    with 'carnet:' while flags intend for Cargo can be prefixed with 
    'cargo:'. If both Carnet and Cargo accept the same flag and 
    prefixes are not used, the handling of this flag is unspecified. 
    The following example illustrates the use of both prefixes:
    
        ${DIM-}carnet --carnet:unsandbox-network test --cargo:release${RESET-}
    
    Both the sandboxing of Cargo and the automatic verification of 
    crates can be disabled, for a single invocation or persistently, 
    through the use of the appropriate flag or by disabling the 
    feature in Carnet's configuration settings:
    
        ${DIM-}carnet --disable-sandbox       ...${RESET-}
        ${DIM-}carnet --disable-verification  ...${RESET-}
        
        ${DIM-}carnet disable sandbox${RESET-}
        ${DIM-}carnet disable verification${RESET-}
    
    ${BOLD-}Sandboxing${RESET-}
    
    By default, Carnet's sandbox restricts Cargo in the following 
    ways:
      
      - No network access
      - Separate process/IPC space
      - Read-only access to the following directories:
        - '/etc'
        - '/bin'
        - '/lib'
        - '/lib64'
        - '/sbin'
        - '/usr'
      - Read-Write access to crate root
      - Read-Write access to a private '/tmp'
      
    You can choose to relax these restrictions partially or fully by
    using the '--unsandbox-*' and '--*-paths' families of flags.
    
    You can explore how Cargo \"sees\" its environment from within 
    the sandbox via sandbox-run:
    
        ${DIM-}carnet ... sandbox-run${RESET-}
        ${DIM-}(i.e. carnet --unsandbox-session sandbox-run bash)${RESET-}
    
    ${BOLD-}Identities (Unstable)${RESET-}
    
    Carnet uses Identities to authenticate crates. An Identity is a 
    set of basic information about a natural, legal, or fictitious 
    person coupled with a single public cryptographic key. One person
    can have multiple identities at the same time. Similarly, crates 
    can be signed by multiple identities at the same time. 
    
    Identities are meant to be ephemeral. They are designed to be 
    trivially generatable, and to be introduced and blacklisted as 
    developers join projects and leave them. Blacklisting an identity 
    does not carry negative connotations by itself; blacklisting 
    simply implies that the identity should no longer be \"trusted\" 
    when verifying crates.

    Identities provide basic information to help users differentiate 
    between trusted keys. Because this information is not verified 
    in any way, a verified crate cannot provide any assurances about 
    the person who signed it. The only 
    assurance it can provide is that whoever signed the crate had 
    access to the identity's private key. Carnet Identities are not 
    designed to protect against the impersonation of 
    others. 

    The basic information identities provide is:

        1. Name (required):   The name or the person using the 
                              identity.
        2. Email (required):  An email address that can be used 
                              to contact this person.
        3. Organization:      The organization of which this 
                              person is member.
        4. Country:           The legal jurisdiction under which
                              this person operates.
                              
    When generating a new identity, Carnet attempts to obtain this 
    information by looking at various sources in the order described 
    bellow:

        ${BOLD-}Identity Name:${RESET-}
  
            CARNET_PUBLISHER_NAME           (environment variable)
            CARGO_NAME                      (environment variable)
            GIT_AUTHOR_NAME                 (environment variable)
            GIT_COMMITTER_NAME              (environment variable)
            user.name                       (git config)
            USER                            (environment variable)
            USERNAME                        (environment variable)
            NAME                            (environment variable)
      
        ${BOLD-}Identity Email:${RESET-}
      
            CARNET_PUBLISHER_EMAIL          (environment variable)
            CARGO_EMAIL                     (environment variable)
            GIT_AUTHOR_EMAIL                (environment variable)
            GIT_COMMITTER_EMAIL             (environment variable)
            user.email                      (git config)
            EMAIL                           (environment variable)
      
        ${BOLD-}Identity Organization:${RESET-}
          
            CARNET_PUBLISHER_ORG            (environment variable)
            CARNET_PUBLISHER_ORGANIZATION   (environment variable)
    
      ${BOLD-}Identity Country:${RESET-}
      
            CARNET_PUBLISHER_COUNTRY        (environment variable)
    
    
    To avoid situations where the private keys of all authorized 
    identities become inaccessible, project authors should ensure 
    identities are properly backed up. Project authors can also add 
    a dedicated \"backup\".
    
    ${BOLD-}Local & Foreign Identity Management (Unstable)${RESET-}
    
    TBD
    
    ${BOLD-}Sealing Crates (Unstable)${RESET-}
    
    TBD
    
    ${BOLD-}Automatic Crate Verification (Unstable)${RESET-}
    
    Carnet verifies the signatures of registered crates automatically
    before running cargo by default. Verification only succeeds when 
    at least one signature from a trusted identity is valid.
    
    To avoid having to repeatedly re-sign crates during development, 
    Carnet can temporarily suspend crate verification, only resuming 
    when a predefined period of time had elapsed or when a condition 
    causes the session to end abruptly. Carnet calls this temporary 
    state a Development Session.
    
    A development Session starts when the user issues the 'edit' 
    command. The session ends when the user issues the 'done' 
    command, time runs out, or when another condition causes the 
    session to end abruptly. A developer session lasts 2 hours by 
    default.
    
    The following example illustrates how development sessions can 
    be manually started and ended:
    
        ${DIM-}carnet carnet:edit${RESET-}
        ${DIM-}# ... 
        ${DIM-}carnet carnet:done${RESET-}
        
    ${BOLD-}Verification Flowchart (Unstable)${RESET-}
    
    The process used to verify a crate can be represented by the 
    following flowchart:
      
        ${DIM-}Was this crate seen before?                                  ${RESET-}
        ${DIM-} |                                                           ${RESET-}
        ${DIM-} +-> no: Is the user willing to trust this crate?            ${RESET-}
        ${DIM-} |    |                                                      ${RESET-}
        ${DIM-} |    +-> no: Authentication Failure                         ${RESET-}
        ${DIM-} |    |                                                      ${RESET-}
        ${DIM-} |    +-> yes: Trust all identities found in this crate      ${RESET-}
        ${DIM-} |         |   when verifying this crate in the future.      ${RESET-}
        ${DIM-} |         |                                                 ${RESET-}
        ${DIM-} |<--------+                                                 ${RESET-}
        ${DIM-} |                                                           ${RESET-}
        ${DIM-} +-> yes: Does it have at least one valid signature issued   ${RESET-}
        ${DIM-}       |  by an identity the user trusts?                    ${RESET-}
        ${DIM-}       |                                                     ${RESET-}
        ${DIM-}       +- no:   Authentication Failure                       ${RESET-}
        ${DIM-}       |                                                     ${RESET-}
        ${DIM-}       +- yes:  Authentication Complete                      ${RESET-}
        ${DIM-}${RESET-}
      
    Carnet associates crates with their paths on your system. This 
    association is used to reliably associate identities with crates.
    For this reason, a crate should not be moved without first 
    \"distrusting\"  it. Once moved, a crate can be re-trusted and 
    re-owned again.
    
    ${BOLD-}Crate State & Ownership (Unstable)${RESET-}
    
    TBD
    
    ${BOLD-}Configuration Settings${RESET-}
    
    Some Carnet settings can be configured persistently through the 
    'enable' and 'disable' commands. The following table describes 
    each available setting along with its default state:
    
        Setting Name        Description
    ---------------------+-------------------------------------------
        sandbox             This setting indicates whether Cargo 
                            should be sandboxed. This setting is 
                            enabled by default.
                            
        verification        This setting indicates whether crates 
                            should be automatically verified. This 
                            setting is enabled by default.
                            
        eula-agreement      This setting indicates the user's 
                            agreement to the terms and conditions 
                            of this software's license agreement. 
                            This setting is disabled by default.

    ${BOLD-}Exit Status${RESET-}  
    
    Cargo exits with code 101 when Cargo errors occur. Carnet exits 
    with code 107 when normal Carnet errors occur and code 108 when 
    internal errors occur.
    
${BOLD-}SUPPORT & LICENSING${RESET-}

    Official commercial support and custom licensing are available 
    directly from the authors of this software. Please send your 
    inquiries via any of our official communication channels. 
    
    Our communication channels are listed at: 
    https://www.ka.com.kw/en/contact


${BOLD-}LICENSE & COPYRIGHT${RESET-}
$COPYRIGHT_BLURB
"


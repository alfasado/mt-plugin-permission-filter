package MT::Plugin::PermissionFilter;
use strict;
use MT;
use MT::Plugin;
use base qw( MT::Plugin );
@MT::Plugin::PermissionFilter::ISA = qw( MT::Plugin );

my $plugin = __PACKAGE__->new( {
    id   => 'PermissionFilter',
    key  => 'permissionfilter',
    name => 'PermissionFilter',
    author_name => 'Alfasado Inc.',
    author_link => 'http://alfasado.net/',
    description => 'PermissionFilter Patch for Movable Type.',
    version => '1.2',
} );

sub init_registry {
    my $plugin = shift;
    my $app = MT->instance();
    my $pkg = 'cms_';
    my $pfx = '$Core::MT::CMS::';
    $plugin->registry( {
        applications => {
            cms => {
                callbacks => {
                    pre_run => sub {
                        my $app = MT->instance;
                        if ( $app->mode eq 'refresh_all_templates' ) {
                            if (! $app->validate_magic() ) {
                                __invalidate_magic( $app );
                            }
                        }
                        if ( $app->mode eq 'itemset_action' ) {
                            if ( my $action = $app->param( 'action_name' ) ) {
                                if ( ( $action eq 'add_tags' ) || ( $action eq 'remove_tags' ) ) {
                                    if (! $app->validate_magic() ) {
                                        __invalidate_magic( $app );
                                    }
                                }
                            }
                        }
                        if ( $app->mode eq 'preview_template' ) {
                            my $perms = $app->blog ? $app->permissions : $app->user->permissions;
                            unless ( $perms || $app->user->is_superuser ) {
                                __invalidate_magic( $app );
                                return $app->return_to_dashboard( permission => 1 );
                            }
                            if ( $perms && !$perms->can_edit_templates ) {
                                __invalidate_magic( $app );
                                return $app->return_to_dashboard( permission => 1 );
                            }
                        }
                        if ( $app->mode eq 'preview_entry' ) {
                            my $perms = $app->blog ? $app->permissions : $app->user->permissions;
                            unless ( $perms || $app->user->is_superuser ) {
                                __invalidate_magic( $app );
                                return $app->return_to_dashboard( permission => 1 );
                            }
                            if ( $perms && ! ( $app->param( '_type' ) eq 'entry' ? $perms->can_create_post : $perms->can_manage_pages ) ) {
                                __invalidate_magic( $app );
                                return $app->return_to_dashboard( permission => 1 );
                            }
                        }
                    },
                    'MT::App::Upgrader::template_param.install' => sub {
                        my ( $cb, $app, $param, $tmpl ) = @_;
                        if ( my $error = $param->{ error } ) {
                            $param->{ error } = MT::Util::encode_html( $error );
                        }
                    },
                    'MT::App::Trackback::template_param.error' => sub {
                        my ( $cb, $app, $param, $tmpl ) = @_;
                        if ( my $error = $param->{ error } ) {
                            $param->{ error } = MT::Util::encode_html( $error );
                        }
                    },
                    # notification
                    $pkg
                        . 'delete_permission_filter.notification' => sub {
                        my $perms = $app->permissions;
                        if ( ! $perms->can_edit_notifications ) {
                            $app->error( $app->translate( 'Invalid request.' ) );
                        }
                    },
                    # banlist
                    $pkg
                        . 'delete_permission_filter.banlist' => sub {
                        my $perms = $app->permissions;
                        unless ( $perms && ( $perms->can_edit_config || $perms->can_manage_feedback ) ) {
                            $app->error( $app->translate( 'Invalid request.' ) );
                        }
                    },
                    # associations
                    $pkg
                        . 'save_permission_filter.association' => sub {
                        $app->error( $app->translate( 'Invalid request.' ) );
                    },
                    # page
                    $pkg
                        . 'save_permission_filter.page' => sub {
                        my ( $eh, $app, $id ) = @_;
                        unless ( ref $id ) {
                            $id = MT->model( 'page' )->load( $id )
                                or return;
                        }
                        return unless $id->isa( 'MT::Page' );
                        my $author = $app->user;
                        return $author->permissions( $id->blog_id )->can_manage_pages;
                    },
                    # asset
                    $pkg
                        . 'save_permission_filter.asset' => sub {
                        my ( $eh, $app, $obj ) = @_;
                        my $author = $app->user;
                        return 1 if $author->is_superuser();
                        if ( $obj && !ref $obj ) {
                            $obj = MT->model( 'asset' )->load( $obj );
                        }
                        my $blog_id = $obj ? $obj->blog_id : ( $app->blog ? $app->blog->id : 0 );
                        return $author->permissions( $blog_id )->can_edit_assets();
                    },
                    # tags
                    $pkg
                        . 'save_permission_filter.tag' => sub {
                        $app->error( $app->translate(  'Invalid request.'  ) );
                    },
                    # log
                    $pkg
                        . 'save_permission_filter.log' => sub {
                        $app->error( $app->translate( 'Invalid request.' ) );
                    },
                    $pkg
                        . 'delete_permission_filter.log' => sub {
                        $app->error( $app->translate( 'Invalid request.' ) );
                    },
                    # config
                    $pkg
                        . 'save_permission_filter.config' => sub {
                        $app->error( $app->translate( 'Invalid request.' ) );
                    },
                    $pkg
                        . 'delete_permission_filter.config' => sub {
                        $app->error( $app->translate( 'Invalid request.' ) );
                    },
                    # fileinfo
                    $pkg
                        . 'save_permission_filter.fileinfo' => sub {
                        $app->error( $app->translate( 'Invalid request.' ) );
                    },
                    $pkg
                        . 'delete_permission_filter.fileinfo' => sub {
                        $app->error( $app->translate( 'Invalid request.' ) );
                    },
                    # objectasset
                    $pkg
                        . 'save_permission_filter.objectasset' => sub {
                        $app->error( $app->translate( 'Invalid request.' ) );
                    },
                    $pkg
                        . 'delete_permission_filter.objectasset' => sub {
                        $app->error( $app->translate( 'Invalid request.' ) );
                    },
                    # objectscore
                    $pkg
                        . 'save_permission_filter.objectscore' => sub {
                        $app->error( $app->translate( 'Invalid request.' ) );
                    },
                    $pkg
                        . 'delete_permission_filter.objectscore' => sub {
                        $app->error( $app->translate( 'Invalid request.' ) );
                    },
                    # objecttag
                    $pkg
                        . 'save_permission_filter.objecttag' => sub {
                        $app->error( $app->translate( 'Invalid request.' ) );
                    },
                    $pkg
                        . 'delete_permission_filter.objecttag' => sub {
                        $app->error( $app->translate( 'Invalid request.' ) );
                    },
                    # permission
                    $pkg
                        . 'save_permission_filter.permission' => sub {
                        $app->error( $app->translate( 'Invalid request.' ) );
                    },
                    $pkg
                        . 'delete_permission_filter.permission' => sub {
                        $app->error( $app->translate( 'Invalid request.' ) );
                    },
                    # plaement
                    $pkg
                        . 'save_permission_filter.placement' => sub {
                        $app->error( $app->translate( 'Invalid request.' ) );
                    },
                    $pkg
                        . 'delete_permission_filter.placement' => sub {
                        $app->error( $app->translate( 'Invalid request.' ) );
                    },
                    # session
                    $pkg
                        . 'save_permission_filter.session' => sub {
                        $app->error( $app->translate( 'Invalid request.' ) );
                    },
                    $pkg
                        . 'delete_permission_filter.session' => sub {
                        $app->error( $app->translate( 'Invalid request.' ) );
                    },
                    # templatemap
                    $pkg
                        . 'save_permission_filter.templatemap' => sub {
                        $app->error( $app->translate( 'Invalid request.' ) );
                    },
                    $pkg
                        . 'delete_permission_filter.templatemap' => sub {
                        $app->error( $app->translate( 'Invalid request.' ) );
                    },
                    # touch
                    $pkg
                        . 'save_permission_filter.touch' => sub {
                        $app->error( $app->translate( 'Invalid request.' ) );
                    },
                    $pkg
                        . 'delete_permission_filter.touch' => sub {
                        $app->error( $app->translate( 'Invalid request.' ) );
                    },
                    # trackback
                    $pkg
                        . 'save_permission_filter.trackback' => sub {
                        $app->error( $app->translate( 'Invalid request.' ) );
                    },
                    $pkg
                        . 'delete_permission_filter.trackback' => sub {
                        $app->error( $app->translate( 'Invalid request.' ) );
                    },
                    # ts_error
                    $pkg
                        . 'save_permission_filter.ts_error' => sub {
                        $app->error( $app->translate( 'Invalid request.' ) );
                    },
                    $pkg
                        . 'delete_permission_filter.ts_error' => sub {
                        $app->error( $app->translate( 'Invalid request.' ) );
                    },
                    # ts_exitstatus
                    $pkg
                        . 'save_permission_filter.ts_exitstatus' => sub {
                        $app->error( $app->translate( 'Invalid request.' ) );
                    },
                    $pkg
                        . 'delete_permission_filter.ts_exitstatus' => sub {
                        $app->error( $app->translate( 'Invalid request.' ) );
                    },
                    # ts_funcmap
                    $pkg
                        . 'save_permission_filter.ts_funcmap' => sub {
                        $app->error( $app->translate( 'Invalid request.' ) );
                    },
                    $pkg
                        . 'delete_permission_filter.ts_funcmap' => sub {
                        $app->error( $app->translate( 'Invalid request.' ) );
                    },
                    # ts_job
                    $pkg
                        . 'save_permission_filter.ts_job' => sub {
                        $app->error( $app->translate( 'Invalid request.' ) );
                    },
                    $pkg
                        . 'delete_permission_filter.ts_job' => sub {
                        $app->error( $app->translate( 'Invalid request.' ) );
                    },
                    # role
                    $pkg
                        . 'delete_permission_filter.role' => sub {
                        if (! $app->user->is_superuser ) {
                            $app->error( $app->translate( 'Invalid request.' ) );
                        }
                        return 1;
                    },
                    # plugindata
                    $pkg
                        . 'save_permission_filter.plugindata' => sub {
                        $app->error( $app->translate( 'Invalid request.' ) );
                    },
                    $pkg
                        . 'delete_permission_filter.plugindata' => sub {
                        $app->error( $app->translate( 'Invalid request.' ) );
                    },
                },
            },
        },
    } );
    if ( ref $app eq 'MT::App::NotifyList' ) {
        my $return_url = $app->base;
        print "Location: $return_url/\n\n";
    }
}

sub __invalidate_magic {
    my $app = shift;
    $app->user( undef );
    if ( ( $app->{ query } ) && ( $app->{ query }->{ param } ) ) {
        $app->{ query }->{ param }->{ __mode } = '';
    }
    $app;
}

MT->add_plugin( $plugin );
1;
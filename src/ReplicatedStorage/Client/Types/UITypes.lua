export type InterfaceNew = ScreenGui & {
    Screen: Frame & {
        Gameplay: Frame & {
            Blood: ImageLabel, 
            MouseUnlocker: TextButton, 
            SensorSpecific: Folder, 
            TeammatesList: Frame & {
                UIPadding: UIPadding, 
                Label: TextLabel, 
                Content: Folder & {
                    ImageLabel: ImageLabel & {
                        UIAspectRatioConstraint: UIAspectRatioConstraint
                    }, 
                    UIGridLayout: UIGridLayout, 
                }
            }, 
            Vignette: ImageLabel, 
            Objectives: Frame & {
                Content: Folder & {
                    DragAndDrop: ImageLabel & {
                        UIAspectRatioConstraint: UIAspectRatioConstraint, 
                        Frame: Frame & {
                            TextLabel: TextLabel
                        }, 
                        UIScale: UIScale, 
                        Content: Frame & {
                            Sections: Folder & {
                                Frame: Frame, 
                                Frame1: Frame, 
                                Frame2: Frame, 
                                Frame3: Frame, 
                                UIGridLayout: UIGridLayout
                            }, 
                            UIAspectRatioConstraint: UIAspectRatioConstraint
                        }, 
                        Description: TextLabel, 
                        Title: TextLabel
                    }, 
                    Reflex: ImageLabel & {
                        Description: TextLabel, 
                        Keybind: TextLabel, 
                        Title: TextLabel, 
                        UIScale: UIScale, 
                        Content: Frame & {
                            Stripe: ImageLabel & {
                                UIGradient: UIGradient, 
                                GreenZone: Frame, 
                                Indicator: Frame, 
                                Border: ImageLabel & {
                                    UIGradient: UIGradient
                                }
                            }, 
                            UIListLayout: UIListLayout, 
                            Stripe: ImageLabel & {
                                UIGradient: UIGradient, 
                                GreenZone: Frame, 
                                Indicator: Frame, 
                                Border: ImageLabel & {
                                    UIGradient: UIGradient
                                }
                            }, 
                            Stripe: ImageLabel & {
                                UIGradient: UIGradient, 
                                Indicator: Frame, 
                                Border: ImageLabel & {
                                    UIGradient: UIGradient
                                }, 
                                GreenZone: Frame
                            }, 
                            Stripe: ImageLabel & {
                                Border: ImageLabel & {
                                    UIGradient: UIGradient
                                }, 
                                GreenZone: Frame, 
                                UIGradient: UIGradient, 
                                Indicator: Frame
                            }, 
                            Stripe: ImageLabel & {
                                Indicator: Frame, 
                                UIGradient: UIGradient, 
                                Border: ImageLabel & {
                                    UIGradient: UIGradient
                                }, 
                                GreenZone: Frame
                            }, 
                            UIPadding: UIPadding
                        }, 
                        UIAspectRatioConstraint: UIAspectRatioConstraint
                    }
                }, 
                Info: Frame & {
                    TextLabel: TextLabel, 
                    Frame: Frame & {
                        UIGradient: UIGradient, 
                        UICorner: UICorner
                    }
                }
            }, 
            Statuses: Frame & {
                Content: Folder & {
                    StatusCard: ImageLabel & {
                        Icon: ImageLabel & {
                            UIAspectRatioConstraint: UIAspectRatioConstraint
                        }, 
                        Value: UIGradient, 
                        StatusName: TextLabel & {
                            UIPadding: UIPadding, 
                            Value: UIGradient
                        }
                    }, 
                    UIListLayout: UIListLayout
                }, 
                UIAspectRatioConstraint: UIAspectRatioConstraint, 
                UIPadding: UIPadding
            }, 
            Misc: Folder & {
                QuickTimeEvent: Frame & {
                    Left: Frame & {
                        Icon: ImageLabel & {
                            Value: UIGradient
                        }
                    }, 
                    UIAspectRatioConstraint: UIAspectRatioConstraint, 
                    Right: Frame & {
                        Icon: ImageLabel & {
                            Value: UIGradient
                        }
                    }
                }, 
                ItemThrowCharge: Frame & {
                    UIGradient: UIGradient
                }, 
                Combo: TextLabel & {
                    Glow: ImageLabel & {
                        UIGradient: UIGradient, 
                        UIAspectRatioConstraint: UIAspectRatioConstraint
                    }, 
                    Indicator: ImageLabel & {
                        UIGradient: UIGradient, 
                        UIAspectRatioConstraint: UIAspectRatioConstraint
                    }
                }, 
                ItemCharge: Frame & {
                    UIAspectRatioConstraint: UIAspectRatioConstraint, 
                    UIGradient: UIGradient
                }
            }, 
            Danger: ImageLabel, 
            Top: Frame & {
                Timer: TextLabel & {
                    Status: TextLabel, 
                    Thumbnail: ImageLabel & {
                        Shadow: ImageLabel
                    }
                }, 
                UIPadding: UIPadding
            }, 
            OtherVignette: ImageLabel, 
            Actions: Frame & {
                Content: Folder & {
                    TextLabel: TextLabel, 
                    TextLabel: TextLabel, 
                    UIListLayout: UIListLayout
                }
            }, 
            PlayerStats: Frame & {
                PlayerName: TextLabel, 
                UIPadding: UIPadding, 
                Bars: Frame & {
                    Stamina: ImageLabel & {
                        UICorner: UICorner, 
                        Value: UIGradient
                    }, 
                    Health: ImageLabel & {
                        UICorner: UICorner, 
                        Value: UIGradient
                    }, 
                    UIListLayout: UIListLayout
                }, 
                Avatar: ImageLabel & {
                    UICorner: UICorner, 
                    UIAspectRatioConstraint: UIAspectRatioConstraint
                }
            }
        }, 
        Global: Frame & {
            MouseUnlocker: TextButton, 
            Interaction: Frame & {
                Content: Folder
            }, 
            Narrative: Frame & {
                UIAspectRatioConstraint: UIAspectRatioConstraint, 
                ResponceLabel: TextLabel
            }, 
            Emotes: Frame & {
                Modal: TextButton, 
                Back: ImageLabel, 
                UIAspectRatioConstraint: UIAspectRatioConstraint, 
                Slots: Folder
            }, 
            Cursor: Frame & {
                UIAspectRatioConstraint: UIAspectRatioConstraint, 
                CrossHair: Folder & {
                    C: Frame, 
                    B: Frame, 
                    D: Frame, 
                    A: Frame
                }, 
                Icon: ImageLabel
            }
        }, 
        Lobby: Frame & {
            Panel: Frame & {
                DisplayName: TextLabel, 
                ImageLabel: ImageLabel & {
                    UIGradient: UIGradient
                }, 
                Points: TextLabel & {
                    ImageLabel: ImageLabel & {
                        UIAspectRatioConstraint: UIAspectRatioConstraint
                    }
                }, 
                Frame1: Frame, 
                PlayerName: TextLabel, 
                Avatar: ImageLabel & {
                    UIAspectRatioConstraint: UIAspectRatioConstraint, 
                    UIGradient: UIGradient
                }, 
                Buttons: Frame & {
                    Stats: ImageButton & {
                        UIAspectRatioConstraint: UIAspectRatioConstraint
                    }, 
                    UIGridLayout: UIGridLayout, 
                    Spectate: ImageButton & {
                        UIAspectRatioConstraint: UIAspectRatioConstraint
                    }, 
                    UpdateLog: ImageButton & {
                        UIAspectRatioConstraint: UIAspectRatioConstraint
                    }, 
                    Settings: ImageButton & {
                        UIAspectRatioConstraint: UIAspectRatioConstraint
                    }, 
                    UIAspectRatioConstraint: UIAspectRatioConstraint
                }
            }, 
            UIPadding: UIPadding, 
            Spectating: Frame & {
                Title: TextLabel & {
                    UIGradient: UIGradient
                }, 
                Subject: TextLabel & {
                    Buttons: Folder & {
                        Next: ImageButton & {
                            UIAspectRatioConstraint: UIAspectRatioConstraint
                        }, 
                        UIListLayout: UIListLayout, 
                        Previous: ImageButton & {
                            UIAspectRatioConstraint: UIAspectRatioConstraint
                        }
                    }, 
                    Username: TextLabel
                }
            }
        }, 
        Notification: Frame & {
            MouseUnlocker: TextButton, 
            Role: Frame & {
                Label: TextLabel & {
                    Frame: Frame
                }, 
                Role: TextLabel, 
                Glow: ImageLabel, 
                Intro: TextLabel
            }, 
            PreparingFrame: Frame & {
                UIPadding: UIPadding, 
                ProgressLabel: TextLabel
            }, 
            Test: Frame & {
                Background: ImageLabel, 
                Modal: TextButton, 
                RoleCharacter: ImageLabel & {
                    UIGradient: UIGradient
                }, 
                Container: Frame & {
                    UIPadding: UIPadding, 
                    Title: ImageLabel & {
                        UIAspectRatioConstraint: UIAspectRatioConstraint
                    }, 
                    Paper: ImageLabel, 
                    LocalStats: Frame & {
                        Grade: ImageLabel & {
                            UIAspectRatioConstraint: UIAspectRatioConstraint, 
                            UIScale: UIScale
                        }, 
                        TextLabel: TextLabel & {
                            UIPadding: UIPadding, 
                            UIStroke: UIStroke
                        }, 
                        Actions: Frame & {
                            Container: ScrollingFrame & {
                                Label: Frame & {
                                    Separator: Frame, 
                                    Title: TextLabel, 
                                    Award: TextLabel
                                }, 
                                UIListLayout: UIListLayout, 
                                Label: Frame & {
                                    Title: TextLabel, 
                                    Separator: Frame, 
                                    Award: TextLabel
                                }, 
                                Points: Frame & {
                                    Title: TextLabel, 
                                    Award: TextLabel
                                }, 
                                Label: Frame & {
                                    Award: TextLabel, 
                                    Title: TextLabel, 
                                    Separator: Frame
                                }, 
                                Label: Frame & {
                                    Separator: Frame, 
                                    Award: TextLabel, 
                                    Title: TextLabel
                                }, 
                                Label: Frame & {
                                    Title: TextLabel, 
                                    Separator: Frame, 
                                    Award: TextLabel
                                }
                            }
                        }
                    }, 
                    Players: Frame & {
                        ["TEACHERS SEP"]: Frame & {
                            Title: TextLabel & {
                                UIPadding: UIPadding
                            }
                        }, 
                        Player: Frame & {
                            Username: TextLabel, 
                            UIListLayout: UIListLayout, 
                            Avatar: ImageLabel & {
                                UICorner: UICorner, 
                                UIAspectRatioConstraint: UIAspectRatioConstraint
                            }
                        }, 
                        ["Player [WE]"]: Frame & {
                            UIListLayout: UIListLayout, 
                            Username: TextLabel, 
                            Avatar: ImageLabel & {
                                UICorner: UICorner, 
                                UIAspectRatioConstraint: UIAspectRatioConstraint
                            }
                        }, 
                        MissBloomie: Frame & {
                            Avatar: ImageLabel & {
                                UIStroke: UIStroke, 
                                UIAspectRatioConstraint: UIAspectRatioConstraint, 
                                UICorner: UICorner
                            }, 
                            UIPadding: UIPadding, 
                            UIListLayout: UIListLayout, 
                            Username: TextLabel & {
                                Role: TextLabel
                            }
                        }, 
                        ["Player [RUINED]"]: Frame & {
                            Data: Folder & {
                                Username: TextLabel, 
                                Avatar: ImageLabel & {
                                    UICorner: UICorner, 
                                    UIAspectRatioConstraint: UIAspectRatioConstraint
                                }, 
                                UIListLayout: UIListLayout
                            }, 
                            ImageLabel: ImageLabel
                        }, 
                        UIListLayout: UIListLayout, 
                        ["STUDENTS SEP"]: Frame & {
                            Title: TextLabel & {
                                UIPadding: UIPadding
                            }
                        }, 
                        MissCircle: Frame & {
                            UIListLayout: UIListLayout, 
                            UIPadding: UIPadding, 
                            Username: TextLabel & {
                                Role: TextLabel
                            }, 
                            Avatar: ImageLabel & {
                                UIAspectRatioConstraint: UIAspectRatioConstraint, 
                                UIStroke: UIStroke, 
                                UICorner: UICorner
                            }
                        }, 
                        MissThavel: Frame & {
                            UIListLayout: UIListLayout, 
                            Avatar: ImageLabel & {
                                UIAspectRatioConstraint: UIAspectRatioConstraint, 
                                UIStroke: UIStroke, 
                                UICorner: UICorner
                            }, 
                            UIPadding: UIPadding, 
                            Username: TextLabel & {
                                Role: TextLabel
                            }
                        }
                    }, 
                    Paper: ImageLabel
                }
            }, 
            RoundResults: Frame & {
                Container: Frame & {
                    Paper: Frame & {
                        Paper: ImageLabel, 
                        LocalStats: Frame & {
                            TextLabel: TextLabel & {
                                UIPadding: UIPadding, 
                                UIStroke: UIStroke
                            }, 
                            Actions: Frame & {
                                Container: ScrollingFrame & {
                                    UIListLayout: UIListLayout, 
                                    Label: Frame & {
                                        Award: TextLabel, 
                                        Separator: Frame, 
                                        Title: TextLabel
                                    }, 
                                    Label: Frame & {
                                        Separator: Frame, 
                                        Title: TextLabel, 
                                        Award: TextLabel
                                    }, 
                                    Label: Frame & {
                                        Separator: Frame, 
                                        Title: TextLabel, 
                                        Award: TextLabel
                                    }, 
                                    Label: Frame & {
                                        Separator: Frame, 
                                        Award: TextLabel, 
                                        Title: TextLabel
                                    }, 
                                    Label: Frame & {
                                        Award: TextLabel, 
                                        Separator: Frame, 
                                        Title: TextLabel
                                    }, 
                                    Points: Frame & {
                                        Title: TextLabel, 
                                        Award: TextLabel
                                    }
                                }
                            }, 
                            Grade: ImageLabel & {
                                UIAspectRatioConstraint: UIAspectRatioConstraint, 
                                UIScale: UIScale
                            }
                        }, 
                        Paper: ImageLabel
                    }, 
                    UIPadding: UIPadding, 
                    Players: Frame & {
                        MissCircle: Frame & {
                            UIPadding: UIPadding, 
                            Username: TextLabel & {
                                Role: TextLabel
                            }, 
                            UIListLayout: UIListLayout, 
                            Avatar: ImageLabel & {
                                UICorner: UICorner, 
                                UIStroke: UIStroke, 
                                UIAspectRatioConstraint: UIAspectRatioConstraint
                            }
                        }, 
                        ["Player [WE]"]: Frame & {
                            UIListLayout: UIListLayout, 
                            Avatar: ImageLabel & {
                                UICorner: UICorner, 
                                UIAspectRatioConstraint: UIAspectRatioConstraint
                            }, 
                            Username: TextLabel
                        }, 
                        ["TEACHERS SEP"]: Frame & {
                            Title: TextLabel & {
                                UIPadding: UIPadding
                            }
                        }, 
                        ["Player [RUINED]"]: Frame & {
                            Data: Folder & {
                                Avatar: ImageLabel & {
                                    UIAspectRatioConstraint: UIAspectRatioConstraint, 
                                    UICorner: UICorner
                                }, 
                                UIListLayout: UIListLayout, 
                                Username: TextLabel
                            }, 
                            ImageLabel: ImageLabel
                        }, 
                        MissBloomie: Frame & {
                            UIPadding: UIPadding, 
                            UIListLayout: UIListLayout, 
                            Username: TextLabel & {
                                Role: TextLabel
                            }, 
                            Avatar: ImageLabel & {
                                UICorner: UICorner, 
                                UIStroke: UIStroke, 
                                UIAspectRatioConstraint: UIAspectRatioConstraint
                            }
                        }, 
                        MissThavel: Frame & {
                            Avatar: ImageLabel & {
                                UIAspectRatioConstraint: UIAspectRatioConstraint, 
                                UICorner: UICorner, 
                                UIStroke: UIStroke
                            }, 
                            UIListLayout: UIListLayout, 
                            UIPadding: UIPadding, 
                            Username: TextLabel & {
                                Role: TextLabel
                            }
                        }, 
                        Player: Frame & {
                            Avatar: ImageLabel & {
                                UIAspectRatioConstraint: UIAspectRatioConstraint, 
                                UICorner: UICorner
                            }, 
                            UIListLayout: UIListLayout, 
                            Username: TextLabel
                        }, 
                        ["STUDENTS SEP"]: Frame & {
                            Title: TextLabel & {
                                UIPadding: UIPadding
                            }
                        }, 
                        UIListLayout: UIListLayout
                    }, 
                    Title: ImageLabel & {
                        UIAspectRatioConstraint: UIAspectRatioConstraint
                    }
                }, 
                Background: ImageLabel, 
                Modal: TextButton, 
                RoleCharacter: ImageLabel & {
                    UIGradient: UIGradient
                }
            }, 
            RoleSelection: Frame & {
                Container: Frame & {
                    Cards: Folder & {
                        UIListLayout: UIListLayout
                    }
                }, 
                Claimed: TextLabel
            }, 
            Achievement: Frame & {
                UIListLayout: UIListLayout, 
                UIPadding: UIPadding
            }
        }, 
        Preloading: Frame & {
            InfoMessage: Frame & {
                Content: Folder & {
                    Headphones: Frame & {
                        Content: TextLabel, 
                        Image: ImageLabel & {
                            UIAspectRatioConstraint: UIAspectRatioConstraint
                        }
                    }, 
                    Title: TextLabel, 
                    Warning: Frame & {
                        Content: TextLabel
                    }
                }
            }, 
            MouseUnlocker: TextButton, 
            Thumbnail: ImageLabel, 
            Info: Frame & {
                Tip: TextLabel, 
                Skip: TextButton, 
                Icon: ImageLabel & {
                    UIAspectRatioConstraint: UIAspectRatioConstraint
                }, 
                Bar: ImageLabel & {
                    fill: ImageLabel & {
                        UIGradient: UIGradient
                    }
                }, 
                Text: TextLabel
            }
        }
    }, 
    PackageLink: PackageLink
}

return nil